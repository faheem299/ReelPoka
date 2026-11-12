package com.godfather.reel_counter

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "reel_counter/native"

    private fun prefs() =
        getSharedPreferences(ReelAccessibilityService.PREFS, Context.MODE_PRIVATE)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTodayCount" ->
                        result.success(prefs().getInt(ReelAccessibilityService.todayKey(), 0))

                    "getLimit" ->
                        result.success(
                            prefs().getInt(
                                ReelAccessibilityService.LIMIT_KEY,
                                ReelAccessibilityService.DEFAULT_LIMIT
                            )
                        )

                    "setLimit" -> {
                        val limit = call.argument<Int>("limit")
                            ?: ReelAccessibilityService.DEFAULT_LIMIT
                        prefs().edit().putInt(ReelAccessibilityService.LIMIT_KEY, limit).apply()
                        result.success(null)
                    }

                    "getLimitEnabled" ->
                        result.success(
                            prefs().getBoolean(ReelAccessibilityService.LIMIT_ENABLED_KEY, false)
                        )

                    "setLimitEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        prefs().edit()
                            .putBoolean(ReelAccessibilityService.LIMIT_ENABLED_KEY, enabled)
                            .apply()
                        result.success(null)
                    }

                    "getHistory" -> {
                        val days = call.argument<Int>("days") ?: 7
                        val list = (days - 1 downTo 0).map {
                            prefs().getInt(ReelAccessibilityService.keyForDaysAgo(it), 0)
                        }
                        result.success(list)
                    }

                    "isServiceEnabled" -> result.success(isServiceEnabled())

                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }

                    "getDistanceStats" -> {
    val p = prefs()
    val today = p.getFloat(ReelAccessibilityService.todayDistKey(), 0f).toDouble()
    val week = (0..6).sumOf {
        p.getFloat(ReelAccessibilityService.distKeyForDaysAgo(it), 0f).toDouble()
    }
    val total = p.all
        .filterKeys { it.startsWith("dist_") }
        .values
        .sumOf { ((it as? Float) ?: 0f).toDouble() }
    result.success(mapOf("today" to today, "week" to week, "total" to total))


}

"getDistanceHistory" -> {
    val days = call.argument<Int>("days") ?: 7
    val list = (days - 1 downTo 0).map {
        prefs().getFloat(ReelAccessibilityService.distKeyForDaysAgo(it), 0f).toDouble()
    }
    result.success(list)
}

"getTheme" -> result.success(prefs().getString("theme_id", "default"))

"setTheme" -> {
    val id = call.argument<String>("id") ?: "default"
    prefs().edit().putString("theme_id", id).apply()
    result.success(null)
}
                    else -> result.notImplemented()
                }
            }
    }

    private fun isServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val me = ComponentName(this, ReelAccessibilityService::class.java)
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == me }
    }
}