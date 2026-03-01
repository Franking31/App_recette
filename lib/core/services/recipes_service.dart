import '../../../features/recipes/data/models/recipe.dart';
import 'api_service.dart';
import 'cache_service.dart';

// ═══════════════════════════════════════════
//  RECIPES SERVICE — Recettes cloud
// ═══════════════════════════════════════════

class RecipesService {
  static Recipe _mapRow(dynamic r) => Recipe.fromJson({
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

  // ── Recherche avancée cloud ────────────────
  // ── Recherche avancée cloud ────────────────
  static Future<List<Recipe>> searchRecipes({
    String query = '',
    String? category,
    int? maxDuration,
    int limit = 20,
  }) async {
    final params = <String, String>{};
    if (query.isNotEmpty) params['q'] = query;
    if (category != null && category != 'Tout') params['category'] = category;
    if (maxDuration != null) params['maxDuration'] = maxDuration.toString();
    params['limit'] = limit.toString();

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final data = await ApiService.get('/recipes/search?$queryString');
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

  // ── Catégories disponibles ─────────────────
  static Future<List<String>> getCategories() async {
    try {
      final data = await ApiService.get('/recipes/categories');
      return List<String>.from(data['categories'] ?? []);
    } catch (_) {
      return [];
    }
  }

  // ── Récupérer recettes cloud ───────────────
  static Future<List<Recipe>> getMyRecipes() async {
    // Hors-ligne → retourne le cache
    if (!CacheService.isOnline) {
      return CacheService.getCachedRecipes();
    }
    try {
      final data = await ApiService.get('/recipes');
      final recipes = (data['recipes'] as List)
          .map((r) => _mapRow(r))
          .toList();
      // Met à jour le cache
      CacheService.cacheRecipes(recipes);
      return recipes;
    } catch (_) {
      // Erreur réseau → fallback cache
      return CacheService.getCachedRecipes();
    }
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
    return _mapRow(data['recipe']);
  }

  // ── Supprimer recette ──────────────────────
  static Future<void> deleteRecipe(String id) async {
    await ApiService.delete('/recipes/$id');
  }
}