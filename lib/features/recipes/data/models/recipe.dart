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
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String?,
    imageUrl: json['imageUrl'] as String?,
    durationMinutes: json['durationMinutes'] as int,
    servings: json['servings'] as int,
    description: json['description'] as String,
    ingredients: List<String>.from(json['ingredients'] as List<dynamic>),
    steps: List<String>.from(json['steps'] as List<dynamic>),
  ); 
  Map<String, dynamic> toJson()=> {
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
}