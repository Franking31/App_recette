import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  AUTH SERVICE v2
//  ✅ Auth anonyme automatique
//  ✅ Upgrade vers compte email
//  ✅ Upgrade vers Google
//  ✅ Session persistante
// ═══════════════════════════════════════════

class AuthUser {
  final String userId;
  final String email;
  final String token;
  final bool isAnonymous;
  final String? displayName;
  final String? avatarUrl;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.token,
    this.isAnonymous = false,
    this.displayName,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        userId: json['userId'] ?? json['user_id'] ?? '',
        email: json['email'] ?? '',
        token: json['token'] ?? '',
        isAnonymous: json['isAnonymous'] == true,
        displayName: json['displayName'],
        avatarUrl: json['avatarUrl'],
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'token': token,
        'isAnonymous': isAnonymous,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
      };

  AuthUser copyWith({
    String? email,
    String? token,
    bool? isAnonymous,
    String? displayName,
    String? avatarUrl,
  }) =>
      AuthUser(
        userId: userId,
        email: email ?? this.email,
        token: token ?? this.token,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

class AuthService {
  static const _key = 'forkai_user';
  static AuthUser? _current;

  static AuthUser? get currentUser => _current;
  static bool get isLoggedIn => _current != null;
  static bool get isAnonymous => _current?.isAnonymous == true;
  static bool get hasRealAccount => _current != null && !(_current!.isAnonymous);

  // ── Init au démarrage ──────────────────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _current = AuthUser.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    // Si pas de session → créer un compte anonyme automatiquement
    if (_current == null) {
      await signInAnonymously();
    }
  }

  // ── Auth anonyme (automatique) ─────────────
  static Future<AuthUser> signInAnonymously() async {
    try {
      final data = await ApiService.post('/auth/anonymous', {});
      final user = AuthUser.fromJson({...data, 'isAnonymous': true});
      await _save(user);
      return user;
    } catch (e) {
      // Fallback local si pas de réseau
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final user = AuthUser(
        userId: localId,
        email: '',
        token: 'local_token',
        isAnonymous: true,
      );
      await _save(user);
      return user;
    }
  }

  // ── Login email ────────────────────────────
  static Future<AuthUser> login(String email, String password) async {
    final data = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
      'anonymousId': isAnonymous ? _current?.userId : null,
    });
    final user = AuthUser.fromJson(data);
    await _save(user);
    return user;
  }

  // ── Signup email ───────────────────────────
  static Future<AuthUser> signup(String email, String password) async {
    final data = await ApiService.post('/auth/signup', {
      'email': email,
      'password': password,
      'anonymousId': isAnonymous ? _current?.userId : null,
    });
    final user = AuthUser.fromJson(data);
    await _save(user);
    return user;
  }

  // ── Upgrade anonyme → email ────────────────
  /// Lie un compte anonyme à un email sans perdre les données
  static Future<AuthUser> linkToEmail(String email, String password) async {
    if (!isAnonymous) throw Exception('Déjà connecté avec un vrai compte');
    final data = await ApiService.post('/auth/link-email', {
      'anonymousId': _current!.userId,
      'email': email,
      'password': password,
    });
    final user = AuthUser.fromJson(data);
    await _save(user);
    return user;
  }

  // ── Upgrade anonyme → Google ───────────────
  /// Lance le flow OAuth Google
  static Future<AuthUser> linkToGoogle() async {
    if (!isAnonymous) throw Exception('Déjà connecté avec un vrai compte');
    // Sur Flutter Web, redirige vers le flow Google OAuth
    final data = await ApiService.post('/auth/link-google', {
      'anonymousId': _current!.userId,
    });
    final user = AuthUser.fromJson(data);
    await _save(user);
    return user;
  }

  // ── Récupérer token ────────────────────────
  static Future<String?> getToken() async {
    if (_current != null) return _current!.token;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      _current = AuthUser.fromJson(jsonDecode(raw));
      return _current!.token;
    } catch (_) {
      return null;
    }
  }

  // ── Logout ─────────────────────────────────
  static Future<void> logout() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    // Recréer un compte anonyme après logout
    await signInAnonymously();
  }

  // ── Sauvegarder ───────────────────────────
  static Future<void> _save(AuthUser user) async {
    _current = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }
}