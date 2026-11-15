import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'auth_page.dart';
import 'friends_page.dart';
import 'avatar.dart';
const _channel = MethodChannel('reel_counter/native');

TextStyle anton({
  double? fontSize,
  double? letterSpacing,
  Color? color,
}) =>
    TextStyle(
      fontFamily: 'Anton',
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      color: color,
    );

TextStyle grotesk({
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  Color? color,
}) =>
    TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );

// ---------------- Formatting ----------------

String formatDistance(double cm) {
  if (cm < 100) return '${cm.toStringAsFixed(0)} cm';
  final m = cm / 100;
  if (m < 1000) return '${m.toStringAsFixed(m < 10 ? 2 : 1)} m';
  final km = m / 1000;
  return '${km.toStringAsFixed(km < 10 ? 2 : 1)} km';
}

String formatDistanceShort(double cm) {
  if (cm < 100) return '${cm.round()}cm';
  final m = cm / 100;
  if (m < 1000) return '${m.toStringAsFixed(m < 10 ? 1 : 0)}m';
  final km = m / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km';
}

// ---------------- Themes ----------------

enum ThemeStyle { standard, cyber, forest }

class AppTheme {
  final String id;
  final String label;
  final ThemeData data;
  final Color reelBar;
  final Color distBar;
  final List<Color>? reelGradient; // optional gradient for the reel bars
  final List<Color>? distGradient; // optional gradient for the distance bars
  final ThemeStyle style;

  const AppTheme({
    required this.id,
    required this.label,
    required this.data,
    required this.reelBar,
    required this.distBar,
    required this.style,
    this.reelGradient,
    this.distGradient,
  });
}

// Cyber Night palette (electric blue and violet)
const _cNavy = Color(0xFF00033D);
const _cNavyDeep = Color(0xFF01021F);
const _cIndigo = Color(0xFF0600AB);
const _cBlue = Color(0xFF0033FF);
const _cViolet = Color(0xFF977DFF);
const _cPink = Color(0xFFFFCCF2);
const _cLight = Color(0xFFF2E6EE);
const _cDanger = Color(0xFFFF6B8A);

// Forest Lime palette
const _fCream = Color(0xFFFFFDEE);
const _fMint = Color(0xFFE2FBCE);
const _fLime = Color(0xFFE3EF26);
const _fTeal = Color(0xFF076653);
const _fDark = Color(0xFF0C342C);
const _fDeep = Color(0xFF06231D);

AppTheme _buildDefault() {
  final data = ThemeData(
    colorSchemeSeed: Colors.deepPurple,
    brightness: Brightness.dark,
    useMaterial3: true,
  );
  return AppTheme(
    id: 'default',
    label: 'Default',
    data: data,
    reelBar: data.colorScheme.primary,
    distBar: data.colorScheme.tertiary,
    style: ThemeStyle.standard,
  );
}

AppTheme _buildCyber() {
  const scheme = ColorScheme.dark(
    primary: _cViolet,
    onPrimary: _cNavy,
    secondary: _cPink,
    onSecondary: _cNavy,
    tertiary: _cPink,
    onTertiary: _cNavy,
    surface: _cNavy,
    onSurface: _cLight,
    error: _cDanger,
    onError: _cNavy,
    primaryContainer: _cIndigo,
    onPrimaryContainer: _cLight,
    errorContainer: Color(0xFF3A0F2A),
    onErrorContainer: _cLight,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: _cNavy,
  );
  final data = base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'SpaceGrotesk',
      bodyColor: _cLight,
      displayColor: _cLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: _cViolet,
      titleTextStyle: anton(fontSize: 24, letterSpacing: 2, color: _cLight),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _cViolet,
        foregroundColor: _cNavy,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _cViolet,
        side: BorderSide(color: _cViolet.withValues(alpha: 0.6), width: 1),
        shape: const StadiumBorder(),
      ),
    ),
  );
  return AppTheme(
    id: 'neon', // keeps your saved choice working
    label: 'Cyber Night',
    data: data,
    reelBar: _cViolet,
    distBar: _cPink,
    reelGradient: const [_cViolet, _cBlue],
    distGradient: const [_cPink, _cViolet],
    style: ThemeStyle.cyber,
  );
}

AppTheme _buildForest() {
  const scheme = ColorScheme.dark(
    primary: _fLime,
    onPrimary: _fDeep,
    secondary: _fMint,
    onSecondary: _fDeep,
    tertiary: _fMint,
    onTertiary: _fDeep,
    surface: _fDark,
    onSurface: _fMint,
    error: Color(0xFFFF8A70),
    onError: _fDeep,
    primaryContainer: _fTeal,
    onPrimaryContainer: _fCream,
    errorContainer: Color(0xFF4A2220),
    onErrorContainer: _fCream,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: _fDeep,
  );
  final data = base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'SpaceGrotesk',
      bodyColor: _fMint,
      displayColor: _fCream,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: _fLime,
      titleTextStyle: grotesk(
          fontSize: 22, fontWeight: FontWeight.bold, color: _fCream),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _fLime,
        foregroundColor: _fDeep,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _fLime,
        side: BorderSide(color: _fLime.withValues(alpha: 0.6), width: 1),
        shape: const StadiumBorder(),
      ),
    ),
  );
  return AppTheme(
    id: 'forest',
    label: 'Forest Lime',
    data: data,
    reelBar: _fLime,
    distBar: _fMint,
    style: ThemeStyle.forest,
  );
}

final List<AppTheme> appThemes = [
  _buildDefault(),
  _buildCyber(),
  _buildForest(),
];

// ---------------- App ----------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.instance.load();
  runApp(const ReelCounterApp());
}

class ReelCounterApp extends StatefulWidget {
  const ReelCounterApp({super.key});

  @override
  State<ReelCounterApp> createState() => _ReelCounterAppState();
}

class _ReelCounterAppState extends State<ReelCounterApp> {
  AppTheme _theme = appThemes.first;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final id = await _channel.invokeMethod<String>('getTheme');
      final found = appThemes.where((t) => t.id == id);
      if (found.isNotEmpty && mounted) setState(() => _theme = found.first);
    } on PlatformException catch (e) {
      debugPrint('getTheme failed: $e');
    }
  }

  Future<void> _setTheme(AppTheme t) async {
    setState(() => _theme = t);
    try {
      await _channel.invokeMethod('setTheme', {'id': t.id});
    } on PlatformException catch (e) {
      debugPrint('setTheme failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reel Counter',
      debugShowCheckedModeBanner: false,
      theme: _theme.data,
            home: ValueListenableBuilder<bool>(
        valueListenable: Api.instance.loggedIn,
        builder: (_, loggedIn, __) => loggedIn
            ? HomePage(theme: _theme, onThemeChanged: _setTheme)
            : const AuthPage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AppTheme theme;
  final ValueChanged<AppTheme> onThemeChanged;
  const HomePage({super.key, required this.theme, required this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _count = 0;
  int _limit = 50;
  bool _limitEnabled = false;
  bool _serviceEnabled = false;
  List<int> _history = List.filled(7, 0);
  List<double> _distHistory = List.filled(7, 0.0);
  double _distToday = 0;
  double _distWeek = 0;
  double _distTotal = 0;
  Timer? _timer;
  String _avatar = defaultAvatar;

    // ---- server sync ----
  String? _syncedDay;
  int? _syncedCount;
  double? _syncedDist;
  DateTime _lastSyncTry = DateTime.fromMillisecondsSinceEpoch(0);
  bool _syncing = false;
  bool _syncFailed = false;
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(forceSync: true);
    _loadMe();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(forceSync: true);
  }

  Future<void> _refresh({bool forceSync = false}) async {
    try {
      final count = await _channel.invokeMethod<int>('getTodayCount') ?? 0;
      final limit = await _channel.invokeMethod<int>('getLimit') ?? 50;
      final limitEnabled =
          await _channel.invokeMethod<bool>('getLimitEnabled') ?? false;
      final enabled =
          await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;
      final raw =
          await _channel.invokeListMethod<int>('getHistory', {'days': 7});
      final distRaw = await _channel
          .invokeListMethod<double>('getDistanceHistory', {'days': 7});
      final dist =
          await _channel.invokeMapMethod<String, dynamic>('getDistanceStats');
      if (!mounted) return;
      setState(() {
        _count = count;
        _limit = limit;
        _limitEnabled = limitEnabled;
        _serviceEnabled = enabled;
        if (raw != null && raw.length == 7) _history = raw;
        if (distRaw != null && distRaw.length == 7) _distHistory = distRaw;
        if (dist != null) {
          _distToday = (dist['today'] as num?)?.toDouble() ?? 0;
          _distWeek = (dist['week'] as num?)?.toDouble() ?? 0;
          _distTotal = (dist['total'] as num?)?.toDouble() ?? 0;
        }
      });
      _sync(force: forceSync);
    } on PlatformException catch (e) {
      debugPrint('Native call failed: $e');
    }
  }
  Future<void> _sync({bool force = false}) async {
    if (_syncing) return;
    final now = DateTime.now();
    final day = dateKey(now);
    final changed = _syncedDay != day ||
        _syncedCount != _count ||
        _syncedDist == null ||
        (_distToday - _syncedDist!).abs() >= 100; // 1 m
    if (!force && !changed) return;
    if (!force && now.difference(_lastSyncTry).inSeconds < 20) return;

    _syncing = true;
    _lastSyncTry = now;
    final count = _count;
    final dist = _distToday;
    try {
      await Api.instance.syncToday(count, dist);
      _syncedDay = day;
      _syncedCount = count;
      _syncedDist = dist;
      if (mounted && _syncFailed) setState(() => _syncFailed = false);
    } on ApiException catch (e) {
      debugPrint('sync failed: $e');
      if (mounted && !_syncFailed) setState(() => _syncFailed = true);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _loadMe() async {
    try {
      final me = await Api.instance.me();
      if (mounted) {
        setState(() => _avatar = (me['avatar'] as String?) ?? defaultAvatar);
      }
    } on ApiException catch (e) {
      debugPrint('me failed: $e');
    }
  }

  Future<void> _changeAvatar() async {
    final picked = await pickAvatar(context, _avatar);
    if (picked == null || picked == _avatar) return;
    final old = _avatar;
    setState(() => _avatar = picked);
    try {
      await Api.instance.setAvatar(picked);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _avatar = old);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleLimit(bool value) async {
    await _channel.invokeMethod('setLimitEnabled', {'enabled': value});
    if (!mounted) return;
    setState(() => _limitEnabled = value);
  }

  Future<void> _changeLimit(int delta) async {
    final newLimit = (_limit + delta).clamp(1, 1000).toInt();
    await _channel.invokeMethod('setLimit', {'limit': newLimit});
    if (!mounted) return;
    setState(() => _limit = newLimit);
  }

  Future<void> _openSettings() =>
      _channel.invokeMethod('openAccessibilitySettings');

  // ---------- Theme picker ----------

  void _pickTheme() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose theme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            for (final t in appThemes)
              ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 9, backgroundColor: t.reelBar),
                    const SizedBox(width: 4),
                    CircleAvatar(radius: 9, backgroundColor: t.distBar),
                  ],
                ),
                title: Text(t.label),
                trailing:
                    t.id == widget.theme.id ? const Icon(Icons.check) : null,
                onTap: () {
                  widget.onThemeChanged(t);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------- Themed building blocks ----------

  ThemeStyle get _style => widget.theme.style;

  String _caps(String s) => _style == ThemeStyle.cyber ? s.toUpperCase() : s;

  Widget _panel({required Widget child}) {
    switch (_style) {
      case ThemeStyle.standard:
        return Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        );
      case ThemeStyle.cyber:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cIndigo, _cNavy],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _cViolet.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
      case ThemeStyle.forest:
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_fDark, _fTeal],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
    }
  }

  Widget _heading(String text) {
    switch (_style) {
      case ThemeStyle.cyber:
        return Text(
          text.toUpperCase(),
          style: anton(fontSize: 17, letterSpacing: 1.4, color: _cViolet),
        );
      case ThemeStyle.forest:
        return Text(
          text,
          style: grotesk(
              fontSize: 18, fontWeight: FontWeight.bold, color: _fLime),
        );
      case ThemeStyle.standard:
        return Text(text, style: Theme.of(context).textTheme.titleMedium);
    }
  }

  BoxDecoration? _background() {
    switch (_style) {
      case ThemeStyle.cyber:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cNavy, _cNavyDeep],
          ),
        );
      case ThemeStyle.forest:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_fDark, _fDeep],
          ),
        );
      case ThemeStyle.standard:
        return null;
    }
  }

  // Big counter. In Cyber Night it gets a vertical gradient (unless the limit is hit).
  Widget _countWidget(TextStyle? style, bool reached) {
    final text = Text('$_count', style: style);
    if (_style == ThemeStyle.cyber && !reached) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cLight, _cViolet],
        ).createShader(rect),
        child: text,
      );
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = widget.theme;
    final reached = _limitEnabled && _count >= _limit;
    final progress =
        _limitEnabled ? (_count / _limit).clamp(0.0, 1.0).toDouble() : 0.0;
    final total = _history.fold<int>(0, (a, b) => a + b);
    final avg = (total / 7).round();

    final TextStyle? countStyle = switch (_style) {
      ThemeStyle.cyber =>
        anton(fontSize: 112, color: reached ? cs.error : _cLight),
      ThemeStyle.forest => grotesk(
          fontSize: 104,
          fontWeight: FontWeight.bold,
          color: reached ? cs.error : _fCream,
        ),
      ThemeStyle.standard => textTheme.displayLarge?.copyWith(
          fontSize: 88,
          fontWeight: FontWeight.bold,
          color: reached ? cs.error : null,
        ),
    };

    final TextStyle? distStyle = switch (_style) {
      ThemeStyle.cyber => anton(fontSize: 34, color: t.distBar),
      ThemeStyle.forest => grotesk(
          fontSize: 34, fontWeight: FontWeight.bold, color: t.distBar),
      ThemeStyle.standard => textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: t.distBar),
    };

    final Color? trackColor = switch (_style) {
      ThemeStyle.cyber => _cIndigo,
      ThemeStyle.forest => _fTeal.withValues(alpha: 0.5),
      ThemeStyle.standard => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_caps('Reel Counter')),
        actions: [
                    Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: _changeAvatar,
              child: AvatarWidget(avatar: _avatar, radius: 16),
            ),
          ),
            IconButton(
            tooltip: 'Friends',
            icon: const Icon(Icons.group_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Themes',
            icon: const Icon(Icons.palette_outlined),
            onPressed: _pickTheme,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => Api.instance.logout(),
          ),
        ],
      ),
      body: Container(
        decoration: _background(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!_serviceEnabled)
              Card(
                color: cs.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Tracking is off'),
                  subtitle: const Text(
                      'Enable the accessibility service to start counting.'),
                  trailing: FilledButton(
                    onPressed: _openSettings,
                    child: const Text('Enable'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Center(child: _countWidget(countStyle, reached)),
            Center(
              child: Text(
                _caps(_limitEnabled ? 'of $_limit reels today' : 'reels today'),
                style: textTheme.titleMedium?.copyWith(
                  letterSpacing: _style == ThemeStyle.cyber ? 2 : null,
                ),
              ),
            ),
            if (_limitEnabled) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: reached ? cs.error : null,
                backgroundColor: trackColor,
              ),
            ],
                        if (_syncFailed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text("Can't reach the server. Friends see old numbers.",
                      style: textTheme.bodySmall?.copyWith(color: cs.error)),
                ),
              ),
            if (reached)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text('Limit reached. Reels are blocked for today.',
                      style: TextStyle(color: cs.error)),
                ),
              ),
            const SizedBox(height: 24),

            // Reels chart
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _heading('Reels, last 7 days'),
                      Text('avg $avg / day', style: textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WeeklyBarChart(
                    values: _history.map((e) => e.toDouble()).toList(),
                    color: t.reelBar,
                    gradient: t.reelGradient,
                    label: (v) => v.round().toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Distance chart
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading('Distance scrolled'),
                  const SizedBox(height: 8),
                  Text(formatDistance(_distToday), style: distStyle),
                  Text(_caps('today'), style: textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DistanceStat(
                            label: 'Last 7 days', value: _distWeek),
                      ),
                      Expanded(
                        child: _DistanceStat(
                            label: 'All time', value: _distTotal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  WeeklyBarChart(
                    values: _distHistory,
                    color: t.distBar,
                    gradient: t.distGradient,
                    label: formatDistanceShort,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Limit
            _panel(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_caps('Daily limit')),
                    subtitle: Text(_limitEnabled
                        ? 'Reels are blocked after $_limit per day'
                        : 'Off: just tracking, no blocking'),
                    value: _limitEnabled,
                    onChanged: _toggleLimit,
                  ),
                  if (_limitEnabled)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                              onPressed: () => _changeLimit(-10),
                              child: const Text('-10')),
                          OutlinedButton(
                              onPressed: () => _changeLimit(-1),
                              child: const Text('-1')),
                          OutlinedButton(
                              onPressed: () => _changeLimit(1),
                              child: const Text('+1')),
                          OutlinedButton(
                              onPressed: () => _changeLimit(10),
                              child: const Text('+10')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceStat extends StatelessWidget {
  final String label;
  final double value;
  const _DistanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatDistance(value),
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: t.bodySmall),
      ],
    );
  }
}

/// One bar per day, oldest on the left, today on the right.
/// If [gradient] is given, bars are filled with that vertical gradient.
class WeeklyBarChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final List<Color>? gradient;
  final String Function(double) label;

  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.color,
    required this.label,
    this.gradient,
  });

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _chartHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final small =
        Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5);
    final maxV = values.fold<double>(0, (m, v) => v > m ? v : m);
    final scale = maxV == 0 ? 1.0 : maxV;
    final now = DateTime.now();
    final g = gradient;

    return SizedBox(
      height: _chartHeight + 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final daysAgo = values.length - 1 - i;
          final date = now.subtract(Duration(days: daysAgo));
          final isToday = daysAgo == 0;
          final barH =
              values[i] <= 0 ? 3.0 : (values[i] / scale) * _chartHeight;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(label(values[i]), style: small),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: barH,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: g == null
                        ? (isToday ? color : color.withValues(alpha: 0.45))
                        : null,
                    gradient: g == null
                        ? null
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isToday
                                ? g
                                : g
                                    .map((c) => c.withValues(alpha: 0.5))
                                    .toList(),
                          ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _days[date.weekday - 1],
                  style: small?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}