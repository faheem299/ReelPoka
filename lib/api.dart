import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const baseUrl = 'http://192.168.0.70:8000'; 

class ApiException implements Exception {
  final int status; // 0 = couldn't reach the server
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Api {
  Api._();
  static final instance = Api._();

  final _store = const FlutterSecureStorage();
  String? _access;
  String? _refresh;

  /// UI listens to this to switch between login screen and home.
  final loggedIn = ValueNotifier<bool>(false);

  Future<void> load() async {
    _access = await _store.read(key: 'access');
    _refresh = await _store.read(key: 'refresh');
    loggedIn.value = _refresh != null;
  }

  Future<void> _save(Map<String, dynamic> tokens) async {
    _access = tokens['access_token'] as String;
    _refresh = tokens['refresh_token'] as String;
    await _store.write(key: 'access', value: _access);
    await _store.write(key: 'refresh', value: _refresh);
    loggedIn.value = true;
  }

  Future<void> logout() async {
    _access = null;
    _refresh = null;
    await _store.delete(key: 'access');
    await _store.delete(key: 'refresh');
    loggedIn.value = false;
  }

  // ---------- Auth ----------

  Future<void> register(String username, String password) async {
    final data = await _call('POST', '/auth/register',
        body: {'username': username, 'password': password}, auth: false);
    await _save(data as Map<String, dynamic>);
  }

  Future<void> login(String username, String password) async {
    final data = await _call('POST', '/auth/login',
        body: {'username': username, 'password': password}, auth: false);
    await _save(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> me() async =>
      await _call('GET', '/auth/me') as Map<String, dynamic>;

  // ---------- Sync ----------

  Future<void> syncToday(int reels, double distanceCm) => _call(
        'PUT',
        '/sync/today',
        body: {
          'day': dateKey(DateTime.now()),
          'reels': reels,
          'distance_cm': distanceCm,
        },
      );

  // ---------- Friends ----------

  Future<List<dynamic>> friendsToday() async =>
      await _call('GET', '/friends/today') as List<dynamic>;

  Future<List<dynamic>> searchUsers(String q) async => await _call(
      'GET', '/friends/search?q=${Uri.encodeQueryComponent(q)}') as List<dynamic>;

  Future<String> sendRequest(String username) async {
    final data = await _call('POST', '/friends/request',
        body: {'username': username}) as Map<String, dynamic>;
    return data['status'] as String; // "pending" or "accepted"
  }

  Future<List<dynamic>> incomingRequests() async =>
      await _call('GET', '/friends/requests') as List<dynamic>;

  Future<void> acceptRequest(int id) =>
      _call('POST', '/friends/requests/$id/accept');

  Future<void> removeFriend(int userId) => _call('DELETE', '/friends/$userId');

  // ---------- Plumbing ----------

  Future<http.Response> _raw(String method, String path, Object? body,
      {required bool auth}) {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (auth && _access != null) 'Authorization': 'Bearer $_access',
    };
    final b = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: b);
      case 'PUT':
        return http.put(uri, headers: headers, body: b);
      case 'DELETE':
        return http.delete(uri, headers: headers);
    }
    throw ArgumentError('Unknown method $method');
  }

  Future<dynamic> _call(String method, String path,
      {Object? body, bool auth = true}) async {
    const timeout = Duration(seconds: 10);
    try {
      var res = await _raw(method, path, body, auth: auth).timeout(timeout);
      if (auth && res.statusCode == 401 && _refresh != null) {
        if (await _refreshTokens()) {
          res = await _raw(method, path, body, auth: auth).timeout(timeout);
        }
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) return null;
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw ApiException(res.statusCode, _detail(res));
    } on TimeoutException {
      throw ApiException(0, "Can't reach the server");
    } on SocketException {
      throw ApiException(0, "Can't reach the server");
    } on http.ClientException {
      throw ApiException(0, "Can't reach the server");
    }
  }

  Future<bool> _refreshTokens() async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': _refresh}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        await _save(jsonDecode(res.body) as Map<String, dynamic>);
        return true;
      }
      if (res.statusCode == 401) await logout(); // refresh token dead
    } catch (_) {}
    return false;
  }

  String _detail(http.Response res) {
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes))['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) {
        final m = (d.first as Map)['msg']?.toString() ?? 'Invalid input';
        return m.replaceFirst('Value error, ', '');
      }
    } catch (_) {}
    return 'Error ${res.statusCode}';
  }
}