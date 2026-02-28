import 'dart:convert';
import 'dart:typed_data';
import 'api_service.dart';
import '../../../features/recipes/data/models/recipe.dart';

// ═══════════════════════════════════════════
//  VISION SERVICE — Photo, Nutrition, Substitution, Planning
// ═══════════════════════════════════════════

// ── Modèles ───────────────────────────────────

class NutritionData {
  final Map<String, double> perPortion;
  final Map<String, double> perRecipe;
  final List<VitaminData> vitamins;
  final int score;
  final String scoreLabel;
  final String scoreColor;
  final List<String> strengths;
  final List<String> improvements;
  final Map<String, bool> dietCompatibility;
  final String glycemicIndex;
  final String tip;

  NutritionData({
    required this.perPortion, required this.perRecipe,
    required this.vitamins, required this.score,
    required this.scoreLabel, required this.scoreColor,
    required this.strengths, required this.improvements,
    required this.dietCompatibility, required this.glycemicIndex,
    required this.tip,
  });

  factory NutritionData.fromJson(Map<String, dynamic> j) => NutritionData(
    perPortion: Map<String, double>.from(
        (j['perPortion'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble()))),
    perRecipe: Map<String, double>.from(
        (j['perRecipe'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble()))),
    vitamins: (j['vitamins'] as List? ?? [])
        .map((v) => VitaminData.fromJson(Map<String, dynamic>.from(v))).toList(),
    score: (j['score'] as num?)?.toInt() ?? 5,
    scoreLabel: j['scoreLabel'] ?? 'Moyen',
    scoreColor: j['scoreColor'] ?? 'orange',
    strengths: List<String>.from(j['strengths'] ?? []),
    improvements: List<String>.from(j['improvements'] ?? []),
    dietCompatibility: Map<String, bool>.from(j['dietCompatibility'] ?? {}),
    glycemicIndex: j['glycemicIndex'] ?? 'Moyen',
    tip: j['tip'] ?? '',
  );
}

class VitaminData {
  final String name;
  final String amount;
  final String daily;
  VitaminData({required this.name, required this.amount, required this.daily});
  factory VitaminData.fromJson(Map<String, dynamic> j) => VitaminData(
    name: j['name'] ?? '', amount: j['amount'] ?? '', daily: j['daily'] ?? '');
}

class SubstituteResult {
  final String ingredient;
  final String reason;
  final List<SubstituteItem> substitutes;
  final String tips;

  SubstituteResult({required this.ingredient, required this.reason,
      required this.substitutes, required this.tips});

  factory SubstituteResult.fromJson(Map<String, dynamic> j) => SubstituteResult(
    ingredient: j['ingredient'] ?? '',
    reason: j['reason'] ?? '',
    substitutes: (j['substitutes'] as List? ?? [])
        .map((s) => SubstituteItem.fromJson(Map<String, dynamic>.from(s))).toList(),
    tips: j['tips'] ?? '',
  );
}

class SubstituteItem {
  final String name;
  final String ratio;
  final String impact;
  final String bestFor;
  final String availability;
  final String emoji;
  final List<String> tags;

  SubstituteItem({required this.name, required this.ratio, required this.impact,
      required this.bestFor, required this.availability, required this.emoji,
      required this.tags});

  factory SubstituteItem.fromJson(Map<String, dynamic> j) => SubstituteItem(
    name: j['name'] ?? '',
    ratio: j['ratio'] ?? '',
    impact: j['impact'] ?? '',
    bestFor: j['best_for'] ?? '',
    availability: j['availability'] ?? '',
    emoji: j['emoji'] ?? '🔄',
    tags: List<String>.from(j['tags'] ?? []),
  );
}

class MealPlan {
  final Map<String, dynamic> weekSummary;
  final List<MealDay> days;
  final List<String> shoppingHighlights;
  final String nutritionBalance;

  MealPlan({required this.weekSummary, required this.days,
      required this.shoppingHighlights, required this.nutritionBalance});

  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
    weekSummary: Map<String, dynamic>.from(j['weekSummary'] ?? {}),
    days: (j['days'] as List? ?? [])
        .map((d) => MealDay.fromJson(Map<String, dynamic>.from(d))).toList(),
    shoppingHighlights: List<String>.from(j['shoppingHighlights'] ?? []),
    nutritionBalance: j['nutritionBalance'] ?? '',
  );
}

class MealDay {
  final String day;
  final String dayEmoji;
  final Map<String, MealItem> meals;
  final int totalCalories;
  final String tip;

  MealDay({required this.day, required this.dayEmoji, required this.meals,
      required this.totalCalories, required this.tip});

  factory MealDay.fromJson(Map<String, dynamic> j) {
    final mealsRaw = j['meals'] as Map? ?? {};
    final meals = mealsRaw.map((k, v) =>
        MapEntry(k as String, MealItem.fromJson(Map<String, dynamic>.from(v))));
    return MealDay(
      day: j['day'] ?? '',
      dayEmoji: j['dayEmoji'] ?? '📅',
      meals: meals,
      totalCalories: (j['totalCalories'] as num?)?.toInt() ?? 0,
      tip: j['tip'] ?? '',
    );
  }
}

class MealItem {
  final String name;
  final String emoji;
  final int duration;
  final int calories;
  final String description;

  MealItem({required this.name, required this.emoji, required this.duration,
      required this.calories, required this.description});

  factory MealItem.fromJson(Map<String, dynamic> j) => MealItem(
    name: j['name'] ?? '',
    emoji: j['emoji'] ?? '🍽️',
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    calories: (j['calories'] as num?)?.toInt() ?? 0,
    description: j['description'] ?? '',
  );
}

// ── Service ───────────────────────────────────
class VisionService {
  // 📸 Photo → Recettes (depuis Uint8List - compatible Web & Mobile)
  static Future<({List<String> ingredients, List<Recipe> recipes, String message})>
      analyzePhotoBytes(Uint8List bytes, {String mimeType = 'image/jpeg', int servings = 4}) async {
    final base64Image = base64Encode(bytes);

    final data = await ApiService.post('/vision/analyze', {
      'image': base64Image,
      'mimeType': mimeType,
      'servings': servings,
    });

    final recipes = (data['recipes'] as List? ?? [])
        .map((r) => Recipe.fromJson(Map<String, dynamic>.from(r))).toList();
    final ingredients = List<String>.from(data['ingredients'] ?? []);

    return (
      ingredients: ingredients,
      recipes: recipes,
      message: (data['message'] ?? '') as String,
    );
  }

  // 🥗 Analyse nutritionnelle
  static Future<NutritionData?> analyzeNutrition({
    required String title,
    required List<String> ingredients,
    required int servings,
  }) async {
    try {
      final data = await ApiService.post('/vision/nutrition', {
        'title': title,
        'ingredients': ingredients,
        'servings': servings,
      });
      return NutritionData.fromJson(Map<String, dynamic>.from(data['nutrition']));
    } catch (_) {
      return null;
    }
  }

  // 🔄 Substitution d'ingrédient
  static Future<SubstituteResult?> getSubstitutes({
    required String ingredient,
    String? context,
    String? diet,
  }) async {
    try {
      final data = await ApiService.post('/vision/substitute', {
        'ingredient': ingredient,
        if (context != null) 'context': context,
        if (diet != null) 'diet': diet,
      });
      return SubstituteResult.fromJson(Map<String, dynamic>.from(data['result']));
    } catch (_) {
      return null;
    }
  }

  // 📅 Planning de repas
  static Future<MealPlan?> generateMealPlan({
    String preferences = '',
    int servings = 2,
    String budget = '',
    String diet = '',
  }) async {
    try {
      final data = await ApiService.post('/vision/meal-plan', {
        'preferences': preferences,
        'servings': servings,
        'budget': budget,
        'diet': diet,
      });
      return MealPlan.fromJson(Map<String, dynamic>.from(data['plan']));
    } catch (_) {
      return null;
    }
  }
}