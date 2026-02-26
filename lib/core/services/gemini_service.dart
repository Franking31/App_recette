import '../../../features/recipes/data/models/recipe.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  GEMINI SERVICE — Appels IA via backend
//  La clé API reste côté serveur !
// ═══════════════════════════════════════════

class GeminiService {
  // ── Chat IA ────────────────────────────────
  static Future<String> chat({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
  }) async {
    final data = await ApiService.post('/ai/chat', {
      'systemPrompt': systemPrompt,
      'messages': messages,
    });
    return data['reply'] as String;
  }

  // ── Générer une recette ────────────────────
  static Future<Recipe> generateRecipe(String query) async {
    final data = await ApiService.post('/ai/generate-recipe', {
      'query': query,
    });
    return Recipe.fromJson(
        Map<String, dynamic>.from(data['recipe']));
  }
}