import 'api_service.dart';
import '../../../features/recipes/data/models/recipe.dart';

class ShareService {
  static const String baseUrl = 'https://forkai-backend.onrender.com';

  // Créer un lien de partage
  static Future<String?> createShareLink(Recipe recipe) async {
    try {
      final data = await ApiService.post('/share', {
        'recipeId': recipe.id,
        'recipeData': recipe.toJson(),
      });
      final token = data['token'] as String;
      return '$baseUrl/api/share/$token';
    } catch (_) {
      return null;
    }
  }

  // Récupérer une recette partagée (depuis app)
  static Future<Recipe?> getSharedRecipe(String token) async {
    try {
      final data = await ApiService.get('/share/$token/json');
      return Recipe.fromJson(Map<String, dynamic>.from(data['recipe']));
    } catch (_) {
      return null;
    }
  }
}