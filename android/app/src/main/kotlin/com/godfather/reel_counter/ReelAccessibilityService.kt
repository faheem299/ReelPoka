package com.godfather.reel_counter

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs

private const val YOUTUBE = "com.google.android.youtube"
private const val INSTAGRAM = "com.instagram.android"
private const val MESSENGER = "com.facebook.orca"
private const val FACEBOOK = "com.facebook.katana"
private const val YT_PAGER_ID = "com.google.android.youtube:id/reel_recycler"
private const val IG_PAGER_ID = "com.instagram.android:id/clips_viewer_view_pager"

private enum class Mode { PAGER, BROWSER, IN_APP, LABELS }

// How to recognise and fingerprint a reel screen in one app.
private class Profile(
    val mode: Mode,
    val pagerIds: List<String> = emptyList(), // PAGER: view ids that exist only on the reel screen
    val textCount: Int = 1,                   // PAGER: how many long texts go into the fingerprint
    val scrollFallback: Boolean = false,      // count on scroll if no fingerprint could be read
    val header: String? = null                // LABELS: title text shown at the top of the reel screen
)

private class Inspect(
    val onReel: Boolean,
    val sig: String?,           // fingerprint of the reel on screen
    val definitelyOff: Boolean  // we know this is NOT a reel screen
)

// Each app keeps its own memory so apps never interfere with each other.
private class AppState {
    var lastCheckAt = 0L
    var lastCountAt = 0L
    var lastSig: String? = null
    var onReel = false
    val seen = HashMap<String, Long>()
}

private val PROFILES = mapOf(
    YOUTUBE to Profile(Mode.PAGER, listOf(YT_PAGER_ID), 1),
    INSTAGRAM to Profile(Mode.PAGER, listOf(IG_PAGER_ID), 2, scrollFallback = true),
    FACEBOOK to Profile(Mode.LABELS, scrollFallback = true, header = "Reels"),
    "com.android.chrome" to Profile(Mode.BROWSER),
    "com.sec.android.app.sbrowser" to Profile(Mode.BROWSER),
    MESSENGER to Profile(Mode.IN_APP)
)

private val TARGET_PACKAGES = PROFILES.keys

// Labels that belong to buttons and navigation, not to the reel itself.
private val UI_LABEL_PARTS = listOf(
    "button", "tab ", "notification", "double tap", "search", "menu", "react to"
)

private fun isUiLabel(s: String): Boolean {
    val l = s.lowercase()
    return UI_LABEL_PARTS.any { l.contains(it) }
}

class ReelAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "ReelCounter"
        const val PREFS = "reel_prefs"
        const val LIMIT_KEY = "daily_limit"
        const val LIMIT_ENABLED_KEY = "limit_enabled"
        const val DEFAULT_LIMIT = 50

        private const val APP_DEBOUNCE_MS = 300L
        private const val BLOCK_THROTTLE_MS = 500L
        private const val CHECK_MS = 250L
        private const val MIN_GAP_MS = 700L
        private const val SEEN_WINDOW_MS = 8000L
        private const val FLUSH_MS = 2000L

        private val REEL_URL_PARTS = listOf(
            "facebook.com/reel",
            "instagram.com/reel",
            "youtube.com/shorts",
            "fb.watch"
        )

        private fun dayKey(prefix: String, daysAgo: Int): String {
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_YEAR, -daysAgo)
            return prefix + SimpleDateFormat("yyyy-MM-dd", Locale.US).format(cal.time)
        }

        fun todayKey(): String = "count_" + SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        fun keyForDaysAgo(daysAgo: Int): String = dayKey("count_", daysAgo)
        fun distKeyForDaysAgo(daysAgo: Int): String = dayKey("dist_", daysAgo)
        fun todayDistKey(): String = distKeyForDaysAgo(0)
    }

    private val handler = Handler(Looper.getMainLooper())
    private var blocking = false
    private var lastBlockAt = 0L
    private var lastDumpAt = 0L
    private val states = HashMap<String, AppState>()

    // Scroll distance tracking
    private var pendingCm = 0f
    private var lastFlushAt = 0L
    private val lastScrollY = HashMap<String, Int>()

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val type = event.eventType
        val pkg = event.packageName?.toString() ?: return

        // Scroll distance: every app except this one, and not while a reel is on screen.
        if (type == AccessibilityEvent.TYPE_VIEW_SCROLLED && pkg != packageName) {
            if (states[pkg]?.onReel != true) recordScroll(event, pkg)
        }

        if (blocking) return
        if (type != AccessibilityEvent.TYPE_VIEW_SCROLLED &&
            type != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED &&
            type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        ) return

        val profile = PROFILES[pkg] ?: return
        val st = states.getOrPut(pkg) { AppState() }

        val now = System.currentTimeMillis()
        if (now - st.lastCheckAt < CHECK_MS) return
        st.lastCheckAt = now

        val root = rootInActiveWindow ?: return
        val ins = inspect(profile, root, now)
        st.onReel = ins.onReel
        if (ins.definitelyOff) st.lastSig = null

        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val limitEnabled = prefs.getBoolean(LIMIT_ENABLED_KEY, false)
        val limit = prefs.getInt(LIMIT_KEY, DEFAULT_LIMIT)
        val count = prefs.getInt(todayKey(), 0)

        // Limit reached: block reel screens, stop counting.
        if (limitEnabled && limit > 0 && count >= limit) {
            if (ins.onReel && now - lastBlockAt >= BLOCK_THROTTLE_MS) {
                lastBlockAt = now
                block(count, limit)
            }
            return
        }

        if (!ins.onReel) return

        val sig = ins.sig
        val shouldCount = when {
            sig != null -> isNewSignature(st, sig, now)
            profile.scrollFallback && type == AccessibilityEvent.TYPE_VIEW_SCROLLED ->
                now - st.lastCountAt > APP_DEBOUNCE_MS
            else -> false
        }
        if (!shouldCount) return
        st.lastCountAt = now

        val newCount = count + 1
        prefs.edit().putInt(todayKey(), newCount).apply()
        Log.d(TAG, "Reel #$newCount / $limit ($pkg)")
    }

    // ---------- Shared counting rule ----------

    private fun isNewSignature(st: AppState, sig: String, now: Long): Boolean {
        if (sig == st.lastSig) return false
        st.lastSig = sig

        val seenAt = st.seen[sig]
        st.seen[sig] = now
        if (st.seen.size > 30) {
            val iter = st.seen.entries.iterator()
            while (iter.hasNext()) {
                if (now - iter.next().value > SEEN_WINDOW_MS) iter.remove()
            }
        }

        Log.d(TAG, "sig: $sig")
        val fresh = seenAt == null || now - seenAt > SEEN_WINDOW_MS
        return fresh && now - st.lastCountAt > MIN_GAP_MS
    }

    // ---------- Per-app inspection ----------

    private fun inspect(profile: Profile, root: AccessibilityNodeInfo, now: Long): Inspect =
        when (profile.mode) {
            Mode.PAGER -> {
                val pager = profile.pagerIds.firstNotNullOfOrNull {
                    root.findAccessibilityNodeInfosByViewId(it).firstOrNull()
                }
                if (pager == null) {
                    Inspect(false, null, true)
                } else {
                    Inspect(true, signatureOf(visibleTexts(pager, 200), profile.textCount), false)
                }
            }
            Mode.BROWSER -> {
                val url = findUrl(root, false)
                val on = isReelUrl(url)
                Inspect(on, if (on) url else null, url != null && !on)
            }
            Mode.IN_APP -> inspectInApp(root, now)
            Mode.LABELS -> inspectLabels(profile, root, now)
        }

    // Facebook app: the Reels screen has a big "Reels" title at the top.
    // The reel is identified by the longest author/caption labels on screen.
    private fun inspectLabels(profile: Profile, root: AccessibilityNodeInfo, now: Long): Inspect {
        val header = profile.header ?: return Inspect(false, null, true)
        val screenH = resources.displayMetrics.heightPixels
        val labels = labelsWithTop(root, 400)

        val hasHeader = labels.any {
            it.first.equals(header, ignoreCase = true) && it.second < screenH * 0.2f
        }
        if (!hasHeader) return Inspect(false, null, true)

        val body = labels.map { it.first }
            .filter { it.length >= 8 && !isUiLabel(it) }
            .distinct()
            .sortedByDescending { it.length }
            .take(2)

        if (body.isEmpty()) {
            dump("fb labels", labels.map { it.first }, now)
            return Inspect(true, null, false)
        }
        return Inspect(true, body.joinToString("|") { it.take(50) }, false)
    }

    // Messenger's built-in browser: use the reel link if it is visible,
    // otherwise recognise a Reels page from its web content.
    private fun inspectInApp(root: AccessibilityNodeInfo, now: Long): Inspect {
        val url = findUrl(root, true)
        if (url != null) return Inspect(true, url, false)

        val web = findWebView(root) ?: return Inspect(false, null, true)
        val texts = visibleTexts(web, 300)
        val hint = texts.any { it.equals("reels", true) || it.equals("reel", true) }
        if (!hint) {
            dump("in-app web texts", texts, now)
            return Inspect(false, null, true)
        }
        return Inspect(true, signatureOf(texts, 1), false)
    }

    // Fingerprint: channel handle (text starting with @) + the longest text(s).
    private fun signatureOf(texts: List<String>, n: Int): String? {
        val handle = texts.firstOrNull { it.startsWith("@") }?.take(40)
        val longest = texts
            .filter { it.length >= 8 }
            .distinct()
            .sortedByDescending { it.length }
            .take(n)
        if (handle == null && longest.isEmpty()) return null
        return "${handle ?: ""}|" + longest.joinToString("|") { it.take(50) }
    }

    private fun visibleTexts(start: AccessibilityNodeInfo, maxNodes: Int): List<String> {
        val out = mutableListOf<String>()
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(start)
        var visited = 0
        while (queue.isNotEmpty() && visited < maxNodes) {
            val node = queue.removeFirst()
            visited++
            if (!node.isVisibleToUser) continue
            val label = node.text?.toString()
            if (!label.isNullOrBlank()) out.add(label)
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return out
    }

    // Visible labels (text, or description if there is no text) with their top edge on screen.
    private fun labelsWithTop(start: AccessibilityNodeInfo, maxNodes: Int): List<Pair<String, Int>> {
        val out = mutableListOf<Pair<String, Int>>()
        val rect = Rect()
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(start)
        var visited = 0
        while (queue.isNotEmpty() && visited < maxNodes) {
            val node = queue.removeFirst()
            visited++
            if (!node.isVisibleToUser) continue
            val label = (node.text?.toString()?.takeIf { it.isNotBlank() }
                ?: node.contentDescription?.toString())?.trim()
            if (!label.isNullOrEmpty()) {
                node.getBoundsInScreen(rect)
                out.add(label to rect.top)
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return out
    }

    private fun isReelUrl(url: String?): Boolean =
        url != null && REEL_URL_PARTS.any { url.contains(it, ignoreCase = true) }

    // Browsers: the address bar (an EditText).
    // Loose mode (in-app browsers): any visible text that contains a reel link.
    private fun findUrl(root: AccessibilityNodeInfo, loose: Boolean): String? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var visited = 0
        while (queue.isNotEmpty() && visited < 400) {
            val node = queue.removeFirst()
            visited++
            val t = node.text?.toString()
            if (node.className?.toString() == "android.widget.EditText") {
                if (!t.isNullOrBlank() && t.contains('.')) return t
            }
            if (loose) {
                if (isReelUrl(t)) return t
                val d = node.contentDescription?.toString()
                if (isReelUrl(d)) return d
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }

    private fun findWebView(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var visited = 0
        while (queue.isNotEmpty() && visited < 400) {
            val node = queue.removeFirst()
            visited++
            if (node.className?.toString() == "android.webkit.WebView") return node
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }

    // Debug: log what the screen exposes when we couldn't make a fingerprint.
    private fun dump(what: String, texts: List<String>, now: Long) {
        if (now - lastDumpAt < 2000) return
        lastDumpAt = now
        Log.d(TAG, "$what: ${texts.take(14).map { it.take(60) }}")
    }

    // ---------- Scroll distance ----------

    private fun recordScroll(event: AccessibilityEvent, pkg: String) {
        val dm = resources.displayMetrics
        var dy = 0
        var dx = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            dy = abs(event.scrollDeltaY)
            dx = abs(event.scrollDeltaX)
        }
        if (dy == 0 && dx == 0 && event.scrollY >= 0) {
            val prev = lastScrollY[pkg]
            if (prev != null) dy = abs(event.scrollY - prev)
            lastScrollY[pkg] = event.scrollY
        }
        if (dy == 0 && dx == 0) return

        val maxPx = dm.heightPixels * 3
        if (dy > maxPx || dx > maxPx) return

        addDistanceCm(pxToCmY(dy.toFloat()) + pxToCmX(dx.toFloat()))
    }

    private fun pxToCmY(px: Float): Float {
        val dm = resources.displayMetrics
        val dpi = if (dm.ydpi > 0f) dm.ydpi else dm.densityDpi.toFloat()
        return px / dpi * 2.54f
    }

    private fun pxToCmX(px: Float): Float {
        val dm = resources.displayMetrics
        val dpi = if (dm.xdpi > 0f) dm.xdpi else dm.densityDpi.toFloat()
        return px / dpi * 2.54f
    }

    private fun addDistanceCm(cm: Float) {
        pendingCm += cm
        val now = System.currentTimeMillis()
        if (now - lastFlushAt >= FLUSH_MS) flushDistance(now)
    }

    private fun flushDistance(now: Long = System.currentTimeMillis()) {
        lastFlushAt = now
        if (pendingCm <= 0f) return
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val key = todayDistKey()
        prefs.edit().putFloat(key, prefs.getFloat(key, 0f) + pendingCm).apply()
        Log.d(TAG, "dist +${"%.1f".format(pendingCm)} cm")
        pendingCm = 0f
    }

    // ---------- Blockade ----------

    private fun block(count: Int, limit: Int) {
        if (blocking) return
        blocking = true
        Toast.makeText(this, "Reel limit reached ($count/$limit)", Toast.LENGTH_SHORT).show()
        Log.d(TAG, "Blocked at $count / $limit")
        exitApp(0)
    }

    private fun exitApp(attempt: Int) {
        val pkg = rootInActiveWindow?.packageName?.toString()
        if (pkg !in TARGET_PACKAGES) {
            blocking = false
            return
        }
        if (attempt >= 6) {
            performGlobalAction(GLOBAL_ACTION_HOME)
            blocking = false
            return
        }
        performGlobalAction(GLOBAL_ACTION_BACK)
        handler.postDelayed({ exitApp(attempt + 1) }, 350)
    }

    override fun onInterrupt() {
        flushDistance()
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        flushDistance()
        return super.onUnbind(intent)
    }
}