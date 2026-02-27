import '../../../features/recipes/data/models/recipe.dart';
import 'api_service.dart';

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

  // ── Générer UNE recette ────────────────────
  static Future<Recipe> generateRecipe(String query, {int servings = 4}) async {
    final data = await ApiService.post('/ai/generate-recipe', {
      'query': query,
      'servings': servings,
    });
    return Recipe.fromJson(Map<String, dynamic>.from(data['recipe']));
  }

  // ── Générer 10 recettes (liste) ────────────
  static Future<List<Recipe>> generateRecipeList(String query, {int servings = 4}) async {
    final data = await ApiService.post('/ai/generate-recipe-list', {
      'query': query,
      'servings': servings,
    });
    return (data['recipes'] as List)
        .map((r) => Recipe.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }
}