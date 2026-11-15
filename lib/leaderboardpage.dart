import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'avatar.dart';
import 'main.dart' show formatDistance;

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> _rows = [];
  bool _loaded = false;
  String? _error;
  Timer? _poll;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.instance.leaderboard();
      if (!mounted) return;
      setState(() {
        _rows = r;
        _loaded = true;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Today. Most reels wins.', style: tt.bodyMedium),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: TextStyle(color: cs.error)),
            if (!_loaded && _error == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_loaded && _rows.length <= 1)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Add friends to start competing.'),
              ),
            for (final r in _rows)
              Builder(builder: (_) {
                final rank = r['rank'] as int;
                final reels = r['reels'] as int;
                final me = r['is_me'] as bool;
                final title = r['title'] as String?;
                final dist = (r['distance_cm'] as num).toDouble();
                final medal =
                    (rank <= 3 && reels > 0) ? _medals[rank - 1] : '$rank';
                return Card(
                  color: me ? cs.primaryContainer : null,
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text(medal,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 6),
                        AvatarWidget(avatar: r['avatar'] as String?),
                      ],
                    ),
                    title: Text('${r['username']}${me ? ' (you)' : ''}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary)),
                        Text('${formatDistance(dist)} scrolled',
                            style: tt.bodySmall),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$reels',
                            style: tt.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text('reels', style: tt.bodySmall),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}