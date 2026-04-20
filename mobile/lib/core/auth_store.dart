import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.teacherId,
    required this.email,
    required this.name,
    required this.role,
  });

  final String token;
  final String teacherId;
  final String email;
  final String name;
  final String role;

  bool get isAdmin => role == 'ADMIN';

  Map<String, dynamic> toJson() => {
        'token': token,
        'teacherId': teacherId,
        'email': email,
        'name': name,
        'role': role,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        teacherId: j['teacherId'] as String,
        email: j['email'] as String,
        name: j['name'] as String,
        role: j['role'] as String,
      );
}

class AuthStore {
  AuthStore(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'bmrs.auth';

  AuthSession? get current {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AuthSession session) async {
    await _prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
