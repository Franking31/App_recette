import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// ═══════════════════════════════════════════
//  API SERVICE — Client HTTP centralisé
//  Toutes les requêtes passent par ici
// ═══════════════════════════════════════════

class ApiService {
  static const String baseUrl = 'https://forkai-backend.onrender.com/api';

  // ── Headers avec token JWT ─────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET ────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  // ── POST ───────────────────────────────────
  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  // ── DELETE ─────────────────────────────────
  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handle(res);
  }

  // ── Handler réponse ────────────────────────
  static Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Erreur serveur ${res.statusCode}');
  }
}