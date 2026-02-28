import 'api_service.dart';

class RecipeRating {
  final String id;
  final String userId;
  final String recipeId;
  final int rating;
  final String? comment;
  final String userEmail;
  final DateTime createdAt;

  RecipeRating({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.rating,
    this.comment,
    required this.userEmail,
    required this.createdAt,
  });

  factory RecipeRating.fromJson(Map<String, dynamic> j) => RecipeRating(
    id: j['id'] ?? '',
    userId: j['user_id'] ?? '',
    recipeId: j['recipe_id'] ?? '',
    rating: (j['rating'] as num?)?.toInt() ?? 0,
    comment: j['comment'],
    userEmail: j['user_email'] ?? 'Anonyme',
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );
}

class RatingStats {
  final double average;
  final int count;
  RatingStats({required this.average, required this.count});
}

class RatingsService {
  static Future<({List<RecipeRating> ratings, RatingStats stats})> getRatings(
      String recipeId) async {
    try {
      final data = await ApiService.get('/ratings/$recipeId');
      final ratings = (data['ratings'] as List)
          .map((r) => RecipeRating.fromJson(Map<String, dynamic>.from(r)))
          .toList();
      final stats = data['stats'] as Map;
      return (
        ratings: ratings,
        stats: RatingStats(
          average: (stats['average'] as num?)?.toDouble() ?? 0,
          count: (stats['count'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (_) {
      return (ratings: <RecipeRating>[], stats: RatingStats(average: 0, count: 0));
    }
  }

  static Future<RecipeRating?> submitRating({
    required String recipeId,
    required int rating,
    String? comment,
    String? userEmail,
  }) async {
    try {
      final data = await ApiService.post('/ratings/$recipeId', {
        'rating': rating,
        'comment': comment,
        'userEmail': userEmail ?? 'Anonyme',
      });
      return RecipeRating.fromJson(Map<String, dynamic>.from(data['rating']));
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteRating(String recipeId) async {
    await ApiService.delete('/ratings/$recipeId');
  }
}