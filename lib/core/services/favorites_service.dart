import 'dart:convert';
import '../../../features/recipes/data/models/recipe.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  FAVORITES SERVICE
// ═══════════════════════════════════════════

class FavoritesService {
  static final Set<String> _favoriteIds = {};
  static bool _loaded = false;

  // ── Charger les favoris ────────────────────
  static Future<List<Recipe>> getFavorites() async {
    final data = await ApiService.get('/favorites');
    final list = (data['favorites'] as List).map((f) {
      final recipe = Recipe.fromJson(
          Map<String, dynamic>.from(f['recipe_data']));
      _favoriteIds.add(recipe.id);
      return recipe;
    }).toList();
    _loaded = true;
    return list;
  }

  // ── Ajouter favori ─────────────────────────
  static Future<void> addFavorite(Recipe recipe) async {
    await ApiService.post('/favorites', {
      'recipeId': recipe.id,
      'recipeData': recipe.toJson(),
    });
    _favoriteIds.add(recipe.id);
  }

  // ── Supprimer favori ───────────────────────
  static Future<void> removeFavorite(String recipeId) async {
    await ApiService.delete('/favorites/$recipeId');
    _favoriteIds.remove(recipeId);
  }

  // ── Toggle favori ──────────────────────────
  static Future<bool> toggleFavorite(Recipe recipe) async {
    if (_favoriteIds.contains(recipe.id)) {
      await removeFavorite(recipe.id);
      return false;
    } else {
      await addFavorite(recipe);
      return true;
    }
  }

  // ── Vérifier si favori (local) ─────────────
  static bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);
}