import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../data/models/recipe.dart';

// ─────────────────────────────────────────────
//  PAGE : RECHERCHE & AJOUT DE RECETTE VIA IA
// ─────────────────────────────────────────────
class AddRecipePage extends StatefulWidget {
  /// Callback appelé quand l'utilisateur confirme l'ajout d'une recette
  final void Function(Recipe recipe) onRecipeAdded;

  const AddRecipePage({super.key, required this.onRecipeAdded});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Recipe? _generatedRecipe;
  String? _errorMessage;

  late AnimationController _shimmerController;
  late AnimationController _cardController;
  late Animation<double> _cardAnim;

  // Suggestions de recherche par thème
  final List<_SearchChip> _suggestions = [
    _SearchChip('🇯🇵 Japon', 'Une recette japonaise traditionnelle'),
    _SearchChip('🇲🇽 Mexique', 'Une recette mexicaine authentique'),
    _SearchChip('🇮🇳 Inde', 'Un curry indien parfumé'),
    _SearchChip('🇹🇭 Thaïlande', 'Un plat thaïlandais épicé'),
    _SearchChip('🇫🇷 France', 'Une recette française classique'),
    _SearchChip('🇲🇦 Maroc', 'Un tajine marocain'),
    _SearchChip('🇬🇷 Grèce', 'Un plat grec méditerranéen'),
    _SearchChip('🇵🇪 Pérou', 'Une recette péruvienne'),
    _SearchChip('🌿 Végétarien', 'Une recette végétarienne équilibrée'),
    _SearchChip('⚡ Rapide', 'Une recette prête en moins de 20 minutes'),
    _SearchChip('🎉 Festif', 'Un plat festif pour recevoir'),
    _SearchChip('❄️ Hiver', 'Un plat chaud et réconfortant'),
    _SearchChip('☀️ Été', 'Une recette fraîche et légère'),
    _SearchChip('🍣 Street food', 'Un street food du monde'),
    _SearchChip('🥐 Brunch', 'Une idée de brunch gourmand'),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardAnim = CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _cardController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── APPEL API ────────────────────────────────
  Future<void> _searchRecipe(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _generatedRecipe = null;
      _errorMessage = null;
    });
    _cardController.reset();

    try {
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) throw Exception('Clé API manquante dans .env');

      final prompt = '''
Génère une recette en lien avec : "$query"

Réponds UNIQUEMENT avec un objet JSON valide, sans markdown, sans commentaire, exactement dans ce format :
{
  "id": "gen_${DateTime.now().millisecondsSinceEpoch}",
  "title": "Nom de la recette",
  "category": "🍽️ Catégorie",
  "imageUrl": null,
  "durationMinutes": 30,
  "servings": 4,
  "description": "Description courte et appétissante en 1-2 phrases.",
  "ingredients": [
    "200g de ...",
    "3 ..."
  ],
  "steps": [
    "Première étape détaillée.",
    "Deuxième étape."
  ]
}

Règles:
- title: nom évocateur et précis
- category: commence toujours par un emoji puis le nom (ex: "🍜 Pâtes")
- durationMinutes: nombre entier réaliste
- servings: nombre entier (entre 1 et 12)
- description: max 150 caractères
- ingredients: entre 4 et 12 éléments, avec quantités précises
- steps: entre 3 et 8 étapes claires
- imageUrl: toujours null
''';

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {'maxOutputTokens': 1024},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

      // Nettoyer et parser le JSON
      final cleanJson = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final recipeJson = jsonDecode(cleanJson) as Map<String, dynamic>;
      final recipe = Recipe.fromJson(recipeJson);

      setState(() {
        _generatedRecipe = recipe;
        _isLoading = false;
      });
      _cardController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }

  void _confirmAdd() {
    if (_generatedRecipe == null) return;
    widget.onRecipeAdded(_generatedRecipe!);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "${_generatedRecipe!.title}" ajoutée !'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _generatedRecipe != null
                      ? _buildRecipePreview()
                      : _buildSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textDark, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter une recette',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Recherchez par pays, ingrédient, style…',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          // Badge IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8604A), Color(0xFFFF8A65)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('🤖', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('IA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BARRE DE RECHERCHE ──────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchRecipe,
                decoration: const InputDecoration(
                  hintText: 'Ex: recette italienne, curry, rapide…',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                  prefixIcon: Icon(Icons.travel_explore_rounded,
                      color: AppColors.primary, size: 22),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _searchRecipe(_searchController.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8604A), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUGGESTIONS ─────────────────────────────
  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspirations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = s.query;
                  _searchRecipe(s.query);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── SKELETON LOADING ────────────────────────
  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmerOpacity =
            0.3 + 0.4 * ((_shimmerController.value * 2 - 1).abs());
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            const Text('✨', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              "L'IA génère votre recette…",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            ...[160.0, 24.0, 80.0, 100.0, 80.0].map((h) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    height: h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: shimmerOpacity),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  // ── APERÇU DE LA RECETTE ────────────────────
  Widget _buildRecipePreview() {
    final recipe = _generatedRecipe!;
    return ScaleTransition(
      scale: _cardAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte recette générée
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder image avec gradient
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.7),
                          AppColors.accent.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Générée par IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Catégorie
                        if (recipe.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              recipe.category!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Infos rapides
                        Row(
                          children: [
                            _chip(Icons.schedule,
                                '${recipe.durationMinutes} min'),
                            const SizedBox(width: 10),
                            _chip(Icons.people, '${recipe.servings} pers.'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ingrédients (aperçu)
            _section('🛒 Ingrédients', recipe.ingredients),

            const SizedBox(height: 16),

            // Étapes (aperçu)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👨‍🍳 Préparation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...recipe.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Boutons action
            Row(
              children: [
                // Régénérer
                Expanded(
                  child: GestureDetector(
                    onTap: () => _searchRecipe(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.cardShadow, blurRadius: 6)
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Régénérer',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ajouter
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _confirmAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8604A), Color(0xFFFF8A65)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Ajouter à mes recettes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textDark)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ],
        ),
      );
}

class _SearchChip {
  final String label;
  final String query;
  const _SearchChip(this.label, this.query);
}