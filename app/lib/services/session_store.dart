import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models.dart';

class StoredSession {
  const StoredSession({this.serverUrl, this.token, this.user});

  final String? serverUrl;
  final String? token;
  final AppUser? user;
}

/// Keeps the login token in the phone's secure storage (Android Keystore / iOS Keychain).
class SessionStore {
  static const _storage = FlutterSecureStorage();

  Future<StoredSession> load() async {
    final values = await _storage.readAll();
    final userJson = values['user'];
    return StoredSession(
      serverUrl: values['serverUrl'],
      token: values['token'],
      user: userJson == null ? null : AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
    );
  }

  Future<void> saveServerUrl(String url) => _storage.write(key: 'serverUrl', value: url);

  Future<void> saveSession(String token, AppUser user) async {
    await _storage.write(key: 'token', value: token);
    await saveUser(user);
  }

  Future<void> saveUser(AppUser user) => _storage.write(key: 'user', value: jsonEncode(user.toJson()));

  Future<void> clearSession() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }
}
