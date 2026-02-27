import '../../../features/recipes/data/models/recipe.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  RECIPES SERVICE — Recettes cloud
// ═══════════════════════════════════════════

class RecipesService {
  // ── Récupérer recettes cloud ───────────────
  static Future<List<Recipe>> getMyRecipes() async {
    final data = await ApiService.get('/recipes');
    return (data['recipes'] as List).map((r) => Recipe.fromJson({
          'id': r['id'],
          'title': r['title'],
          'category': r['category'],
          'imageUrl': r['image_url'],
          'durationMinutes': r['duration_minutes'],
          'servings': r['servings'],
          'description': r['description'] ?? '',
          'ingredients': List<String>.from(r['ingredients'] ?? []),
          'steps': List<String>.from(r['steps'] ?? []),
        })).toList();
  }

  // ── Sauvegarder recette ────────────────────
  static Future<Recipe> saveRecipe(Recipe recipe,
      {bool isAiGenerated = false}) async {
    final data = await ApiService.post('/recipes', {
      'title': recipe.title,
      'category': recipe.category,
      'imageUrl': recipe.imageUrl,
      'durationMinutes': recipe.durationMinutes,
      'servings': recipe.servings,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'steps': recipe.steps,
      'isAiGenerated': isAiGenerated,
    });
    final r = data['recipe'];
    return Recipe.fromJson({
      'id': r['id'],
      'title': r['title'],
      'category': r['category'],
      'imageUrl': r['image_url'],
      'durationMinutes': r['duration_minutes'],
      'servings': r['servings'],
      'description': r['description'] ?? '',
      'ingredients': List<String>.from(r['ingredients'] ?? []),
      'steps': List<String>.from(r['steps'] ?? []),
    });
  }

  // ── Supprimer recette ──────────────────────
  static Future<void> deleteRecipe(String id) async {
    await ApiService.delete('/recipes/$id');
  }
}