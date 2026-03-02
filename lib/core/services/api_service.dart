import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://forkai-backend.onrender.com/api';

  // Délais entre les appels au démarrage pour éviter les 429
  static const _kRetryDelays = [1, 2, 4]; // secondes

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET avec retry + backoff exponentiel sur 429 ──
  static Future<Map<String, dynamic>> get(String path) async {
    return _withRetry(() async {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
      return res;
    });
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    return _withRetry(() async {
      final res = await http.post(Uri.parse('$baseUrl$path'),
          headers: await _headers(), body: jsonEncode(body));
      return res;
    });
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    return _withRetry(() async {
      final res = await http.put(Uri.parse('$baseUrl$path'),
          headers: await _headers(), body: jsonEncode(body));
      return res;
    });
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    return _withRetry(() async {
      final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
      return res;
    });
  }

  // ── Retry avec backoff exponentiel ────────────────
  static Future<Map<String, dynamic>> _withRetry(
    Future<http.Response> Function() call,
  ) async {
    for (int attempt = 0; attempt <= _kRetryDelays.length; attempt++) {
      final res = await call();

      // Succès
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return _handle(res);
      }

      // 429 Too Many Requests → on attend avant de réessayer
      if (res.statusCode == 429 && attempt < _kRetryDelays.length) {
        final delay = _kRetryDelays[attempt];
        await Future.delayed(Duration(seconds: delay));
        continue;
      }

      // Autre erreur → on lance l'exception
      return _handle(res);
    }
    throw Exception('Trop de requêtes. Réessaie dans quelques secondes.');
  }

  static Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['error'] ?? 'Erreur serveur ${res.statusCode}');
  }
}