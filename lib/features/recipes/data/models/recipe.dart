class Recipe {
  final String id;
  final String title;
  final String? category;
  final String? imageUrl;
  final int durationMinutes;
  final int servings;
  final String description;
  final List<String> ingredients;
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    this.category,
    this.imageUrl,
    required this.durationMinutes,
    required this.servings,
    required this.description,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? 'Sans titre').toString(),
    category: json['category']?.toString(),
    imageUrl: json['imageUrl']?.toString(),
    durationMinutes: _toInt(json['durationMinutes'], 30),
    servings: _toInt(json['servings'], 4),
    description: (json['description'] ?? '').toString(),
    ingredients: _toStringList(json['ingredients']),
    steps: _toStringList(json['steps']),
  );

  static int _toInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'imageUrl': imageUrl,
    'durationMinutes': durationMinutes,
    'servings': servings,
    'description': description,
    'ingredients': ingredients,
    'steps': steps,
  };

  // ── CopyWith ───────────────────────────────
  Recipe copyWith({
    String? id,
    String? title,
    String? category,
    String? imageUrl,
    int? durationMinutes,
    int? servings,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
  }) =>
      Recipe(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        servings: servings ?? this.servings,
        description: description ?? this.description,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
      );
}