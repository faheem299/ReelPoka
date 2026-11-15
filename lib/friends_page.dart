import 'dart:async';

import 'package:flutter/material.dart';
import 'leaderboardpage.dart';
import 'api.dart';
import 'main.dart' show formatDistance;
import 'avatar.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _search = TextEditingController();
  List<dynamic> _friends = [];
  List<dynamic> _requests = [];
  List<dynamic>? _results; // null = not searching
  bool _loaded = false;
  String? _error;
  Timer? _poll;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        Api.instance.friendsToday(),
        Api.instance.incomingRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = r[0];
        _requests = r[1];
        _loaded = true;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 2) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await Api.instance.searchUsers(query);
        if (mounted && _search.text.trim() == query) {
          setState(() => _results = r);
        }
      } on ApiException catch (e) {
        _toast(e.message);
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add(String username) async {
    try {
      final s = await Api.instance.sendRequest(username);
      _toast(s == 'accepted'
          ? 'You are now friends with $username'
          : 'Request sent to $username');
      _search.clear();
      setState(() => _results = null);
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _accept(int id) async {
    try {
      await Api.instance.acceptRequest(id);
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _remove(int userId, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $username?'),
        content: const Text('You will no longer see each other\'s numbers.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.instance.removeFriend(userId);
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  String _ago(String? iso) {
    if (iso == null) return 'no data yet';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'updated just now';
    if (d.inMinutes < 60) return 'updated ${d.inMinutes} min ago';
    if (d.inHours < 24) return 'updated ${d.inHours} h ago';
    return 'updated ${d.inDays} d ago';
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = dateKey(DateTime.now());

    return Scaffold(
            appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _search,
              onChanged: _onQuery,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: 'Find a username',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _results = null);
                        },
                      ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),

            // ---- search results ----
            if (_results != null) ...[
              _label('Results'),
              if (_results!.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No users found'),
                ),
              for (final u in _results!)
                ListTile(
                  leading: AvatarWidget(avatar: u['avatar'] as String?),
                  title: Text(u['username'] as String),
                  trailing: FilledButton(
                    onPressed: () => _add(u['username'] as String),
                    child: const Text('Add'),
                  ),
                ),
            ] else ...[
              // ---- incoming requests ----
              if (_requests.isNotEmpty) ...[
                _label('Requests'),
                for (final r in _requests)
                  Card(
                    child: ListTile(
                      leading: AvatarWidget(avatar: r['from_avatar'] as String?),
                      title: Text(r['from_username'] as String),
                      subtitle: const Text('wants to be your friend'),
                      trailing: FilledButton(
                        onPressed: () => _accept(r['id'] as int),
                        child: const Text('Accept'),
                      ),
                    ),
                  ),
              ],

              // ---- friends ----
              _label('Friends'),
              if (!_loaded && _error == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_loaded && _friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No friends yet. Search a username above.'),
                ),
              for (final f in _friends)
                Builder(builder: (_) {
                  // A row from another day means nothing yet today.
                  final isToday = f['day'] == today;
                  final reels = isToday ? f['reels'] as int : 0;
                  final dist =
                      isToday ? (f['distance_cm'] as num).toDouble() : 0.0;
                  final name = f['username'] as String;
                  return Card(
                    child: ListTile(
                      onLongPress: () => _remove(f['id'] as int, name),
                      leading: AvatarWidget(avatar: f['avatar'] as String?),
                      title: Text(name),
                      subtitle: Text(_ago(f['updated_at'] as String?)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$reels reels',
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${formatDistance(dist)} scrolled',
                              style: tt.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }),
              if (_friends.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Long-press a friend to remove them.',
                      textAlign: TextAlign.center, style: tt.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}