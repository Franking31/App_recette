import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  AUTH SERVICE — Gestion session utilisateur
// ═══════════════════════════════════════════

class AuthUser {
  final String userId;
  final String email;
  final String token;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        userId: json['userId'],
        email: json['email'],
        token: json['token'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'token': token,
      };
}

class AuthService {
  static const _key = 'forkai_user';
  static AuthUser? _current;

  // ── User courant ───────────────────────────
  static AuthUser? get currentUser => _current;
  static bool get isLoggedIn => _current != null;

  // ── Charger session au démarrage ───────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _current = AuthUser.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
  }

  // ── Récupérer token ────────────────────────
  static Future<String?> getToken() async {
    if (_current != null) return _current!.token;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final user = AuthUser.fromJson(jsonDecode(raw));
      _current = user;
      return user.token;
    } catch (_) {
      return null;
    }
  }

  // ── Login ──────────────────────────────────
  static Future<AuthUser> login(String email, String password) async {
    final data = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final user = AuthUser.fromJson(data);
    await _save(user);
    return user;
  }

  // ── Signup ─────────────────────────────────
  static Future<AuthUser> signup(String email, String password) async {
    final data = await ApiService.post('/auth/signup', {
      'email': email,
      'password': password,
    });
    final user = AuthUser.fromJson(data);
    await _save(user);
    return user;
  }

  // ── Logout ─────────────────────────────────
  static Future<void> logout() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ── Sauvegarder session ────────────────────
  static Future<void> _save(AuthUser user) async {
    _current = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }
}