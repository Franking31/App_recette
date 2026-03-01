import 'dart:convert';
import '../../../features/recipes/data/models/recipe.dart';
import 'api_service.dart';

// ═══════════════════════════════════════════
//  USER PREFS SERVICE — IA qui apprend
// ═══════════════════════════════════════════

class UserPrefs {
  final List<String> likedCategories;
  final List<String> dislikedCategories;
  final List<String> ignoredRecipes;
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final int? avgCookTime;
  final double? avgBudget;
  final String? dominantCuisine;
  final String skillLevel;
  final String? goal;
  final int totalRecipesSaved;
  final int totalRecipesCooked;

  const UserPrefs({
    this.likedCategories = const [],
    this.dislikedCategories = const [],
    this.ignoredRecipes = const [],
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.avgCookTime,
    this.avgBudget,
    this.dominantCuisine,
    this.skillLevel = 'débutant',
    this.goal,
    this.totalRecipesSaved = 0,
    this.totalRecipesCooked = 0,
  });

  factory UserPrefs.fromJson(Map<String, dynamic> j) => UserPrefs(
        likedCategories: List<String>.from(j['liked_categories'] ?? []),
        dislikedCategories: List<String>.from(j['disliked_categories'] ?? []),
        ignoredRecipes: List<String>.from(j['ignored_recipes'] ?? []),
        dietaryRestrictions: List<String>.from(j['dietary_restrictions'] ?? []),
        allergies: List<String>.from(j['allergies'] ?? []),
        avgCookTime: j['avg_cook_time'] as int?,
        avgBudget: (j['avg_budget'] as num?)?.toDouble(),
        dominantCuisine: j['dominant_cuisine'] as String?,
        skillLevel: j['skill_level'] as String? ?? 'débutant',
        goal: j['goal'] as String?,
        totalRecipesSaved: j['total_recipes_saved'] as int? ?? 0,
        totalRecipesCooked: j['total_recipes_cooked'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'liked_categories': likedCategories,
        'disliked_categories': dislikedCategories,
        'ignored_recipes': ignoredRecipes,
        'dietary_restrictions': dietaryRestrictions,
        'allergies': allergies,
        'avg_cook_time': avgCookTime,
        'avg_budget': avgBudget,
        'dominant_cuisine': dominantCuisine,
        'skill_level': skillLevel,
        'goal': goal,
        'total_recipes_saved': totalRecipesSaved,
        'total_recipes_cooked': totalRecipesCooked,
      };

  UserPrefs copyWith({
    List<String>? likedCategories,
    List<String>? dislikedCategories,
    List<String>? ignoredRecipes,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    int? avgCookTime,
    double? avgBudget,
    String? dominantCuisine,
    String? skillLevel,
    String? goal,
    int? totalRecipesSaved,
    int? totalRecipesCooked,
  }) => UserPrefs(
        likedCategories: likedCategories ?? this.likedCategories,
        dislikedCategories: dislikedCategories ?? this.dislikedCategories,
        ignoredRecipes: ignoredRecipes ?? this.ignoredRecipes,
        dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
        allergies: allergies ?? this.allergies,
        avgCookTime: avgCookTime ?? this.avgCookTime,
        avgBudget: avgBudget ?? this.avgBudget,
        dominantCuisine: dominantCuisine ?? this.dominantCuisine,
        skillLevel: skillLevel ?? this.skillLevel,
        goal: goal ?? this.goal,
        totalRecipesSaved: totalRecipesSaved ?? this.totalRecipesSaved,
        totalRecipesCooked: totalRecipesCooked ?? this.totalRecipesCooked,
      );
}

class UserPrefsService {
  static UserPrefs? _cached;

  // ── Charger les préférences ───────────────
  static Future<UserPrefs> getPrefs({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;
    try {
      final data = await ApiService.get('/prefs');
      _cached = UserPrefs.fromJson(
          Map<String, dynamic>.from(data['prefs'] ?? {}));
      return _cached!;
    } catch (_) {
      return _cached ?? const UserPrefs();
    }
  }

  // ── Sauvegarder les préférences ───────────
  static Future<void> savePrefs(UserPrefs prefs) async {
    _cached = prefs;
    await ApiService.put('/prefs', prefs.toJson());
  }

  // ── Tracking silencieux ───────────────────
  // Appelé automatiquement, ne bloque pas l'UI
  static void trackEvent(String event, Map<String, dynamic> data) {
    ApiService.post('/prefs/track', {
      'event': event,
      'data': data,
    }).catchError((_) {}); // silencieux
  }

  // Raccourcis tracking
  static void trackRecipeSaved(Recipe recipe) => trackEvent('recipe_saved', {
        'category': recipe.category,
        'durationMinutes': recipe.durationMinutes,
        'title': recipe.title,
      });

  static void trackRecipeIgnored(Recipe recipe) => trackEvent('recipe_ignored', {
        'category': recipe.category,
        'title': recipe.title,
      });

  static void trackRecipeCooked(Recipe recipe) => trackEvent('recipe_cooked', {
        'category': recipe.category,
        'title': recipe.title,
      });

  // ── Recette surprise ──────────────────────
  static Future<Map<String, dynamic>> getSurpriseRecipe() async {
    final data = await ApiService.post('/prefs/surprise', {});
    return Map<String, dynamic>.from(data['recipe'] ?? {});
  }

  static UserPrefs? get cached => _cached;
  static void invalidate() => _cached = null;
}