import 'dart:async';

import 'package:flutter/material.dart';
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
  List<dynamic> _board = [];
  static const _medals = ['🥇', '🥈', '🥉'];
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
        Api.instance.leaderboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = r[0];
        _requests = r[1];
        _board = r[2];
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
  // Medal for a friend who is in today's top 3, otherwise empty.
  String _medal(int userId) {
    for (final r in _board) {
      if (r['id'] == userId &&
          (r['reels'] as int) > 0 &&
          (r['rank'] as int) <= 3) {
        return '${_medals[(r['rank'] as int) - 1]} ';
      }
    }
    return '';
  }

  Widget _topThree() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // The board is sorted, so the first three with reels are the top three.
    final top = _board.where((r) => (r['reels'] as int) > 0).take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Top 3 today'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final r in top)
                ListTile(
                  tileColor: (r['is_me'] as bool) ? cs.primaryContainer : null,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_medals[(r['rank'] as int) - 1],
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      AvatarWidget(avatar: r['avatar'] as String?),
                    ],
                  ),
                  title: Text(
                      '${r['username']}${(r['is_me'] as bool) ? ' (you)' : ''}'),
                  subtitle: Text(
                    (r['title'] as String?) ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${r['reels']} reels',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                          '${formatDistance((r['distance_cm'] as num).toDouble())} scrolled',
                          style: tt.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
            appBar: AppBar(title: const Text('Friends')),
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
              if (_friends.isNotEmpty) _topThree(),
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
                      title: Text('${_medal(f['id'] as int)}$name'),
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