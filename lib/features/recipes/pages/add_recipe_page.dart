import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/models/recipe.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/recipes_service.dart';
import '../../../core/services/auth_service.dart';

// ═══════════════════════════════════════════
//  ADD RECIPE PAGE — Génération IA (liste 10)
// ═══════════════════════════════════════════
class AddRecipePage extends StatefulWidget {
  final void Function(Recipe recipe) onRecipeAdded;
  const AddRecipePage({super.key, required this.onRecipeAdded});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<Recipe> _generatedList = [];
  int _servings = 4;

  late AnimationController _shimmerCtrl;

  final List<_Chip> _suggestions = [
    _Chip('🇯🇵 Japon', 'Une recette japonaise traditionnelle'),
    _Chip('🇲🇽 Mexique', 'Une recette mexicaine authentique'),
    _Chip('🇮🇳 Inde', 'Un curry indien parfumé'),
    _Chip('🇹🇭 Thaïlande', 'Un plat thaïlandais épicé'),
    _Chip('🇫🇷 France', 'Une recette française classique'),
    _Chip('🇲🇦 Maroc', 'Un tajine marocain'),
    _Chip('🇬🇷 Grèce', 'Un plat grec méditerranéen'),
    _Chip('🌿 Végétarien', 'Une recette végétarienne équilibrée'),
    _Chip('⚡ Rapide', 'Une recette prête en moins de 20 minutes'),
    _Chip('🎉 Festif', 'Un plat festif pour recevoir'),
    _Chip('❄️ Hiver', 'Un plat chaud et réconfortant'),
    _Chip('🍣 Street food', 'Un street food du monde'),
    _Chip('🥐 Brunch', 'Une idée de brunch gourmand'),
    _Chip('🥩 Viandes', 'Un plat à base de viande savoureux'),
    _Chip('🐟 Poissons', 'Une recette de poisson ou fruits de mer'),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _generatedList = [];
      _errorMessage = null;
    });
    try {
      final list = await GeminiService.generateRecipeList(query, servings: _servings);
      if (mounted) setState(() { _generatedList = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = '$e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✨ Générer des recettes',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
                        Text("L'IA génère 10 recettes au choix",
                            style: TextStyle(fontSize: 12, color: textLight)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE8604A), Color(0xFFFF8A65)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('IA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── RECHERCHE + PERSONNES ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: surface, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(Icons.search, color: textLight, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(color: textDark, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ex: japonais, végétarien, rapide...',
                              hintStyle: TextStyle(color: textLight, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: _generate,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _generate(_searchCtrl.text),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Générer', style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: surface, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('Nombre de personnes', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: textDark)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() { if (_servings > 1) _servings--; }),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove, color: AppColors.primary, size: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_servings', style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() { if (_servings < 20) _servings++; }),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: AppColors.primary, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── CONTENU ───────────────────────
            Expanded(
              child: _isLoading
                  ? _buildSkeleton(surface)
                  : _errorMessage != null
                      ? _buildError(textLight)
                      : _generatedList.isNotEmpty
                          ? _buildRecipeList(isDark, surface, textDark, textLight)
                          : _buildSuggestions(surface, textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(Color surface, Color textDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Idées de recherche', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _suggestions.map((s) => GestureDetector(
              onTap: () {
                _searchCtrl.text = s.label;
                _generate(s.query);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                ),
                child: Text(s.label, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: textDark)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(Color surface) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LinearProgressIndicator(
                value: _shimmerCtrl.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(AppColors.primary.withOpacity(0.1)),
                minHeight: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 13, decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 120, decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4))),
                  ],
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecipeList(bool isDark, Color surface, Color textDark, Color textLight) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${_generatedList.length} recettes générées',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => _generate(_searchCtrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.refresh, color: AppColors.primary, size: 14),
                    SizedBox(width: 4),
                    Text('Regénérer', style: TextStyle(
                        fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _generatedList.length,
            itemBuilder: (ctx, i) => _RecipeListTile(
              recipe: _generatedList[i],
              index: i,
              isDark: isDark,
              servings: _servings,
              onAdded: (recipe) {
                widget.onRecipeAdded(recipe);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('✅ "${recipe.title}" ajoutée !'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Color textLight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Erreur de génération', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: textLight)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', style: TextStyle(color: textLight, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _generate(_searchCtrl.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Tuile recette dans la liste
// ─────────────────────────────────────────────
class _RecipeListTile extends StatelessWidget {
  final Recipe recipe;
  final int index;
  final bool isDark;
  final int servings;
  final void Function(Recipe) onAdded;

  const _RecipeListTile({
    required this.recipe, required this.index, required this.isDark,
    required this.servings, required this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final catColor = AppColors.categoryColor(recipe.category);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _RecipePreviewPage(
          recipe: recipe, isDark: isDark, servings: servings, onAdded: onAdded,
        )),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: recipe.imageUrl != null
                      ? Image.network(
                          recipe.imageUrl!,
                          width: 52, height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _numBadge(index, catColor),
                        )
                      : _numBadge(index, catColor),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: catColor, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                          style: const TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.category != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(recipe.category!, style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: catColor)),
                    ),
                  Text(recipe.title, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: textDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.schedule, size: 12, color: textLight),
                    const SizedBox(width: 3),
                    Text('${recipe.durationMinutes} min', style: TextStyle(fontSize: 11, color: textLight)),
                    const SizedBox(width: 8),
                    Icon(Icons.people_outline, size: 12, color: textLight),
                    const SizedBox(width: 3),
                    Text('$servings pers.', style: TextStyle(fontSize: 11, color: textLight)),
                    const SizedBox(width: 8),
                    Icon(Icons.restaurant_menu, size: 12, color: textLight),
                    const SizedBox(width: 3),
                    Text('${recipe.ingredients.length} ingr.', style: TextStyle(fontSize: 11, color: textLight)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textLight),
          ],
        ),
      ),
    );
  }

  Widget _numBadge(int index, Color color) => Container(
    width: 52, height: 52,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Text('${index + 1}', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, color: color)),
    ),
  );
}

// ─────────────────────────────────────────────
//  Page preview + édition
// ─────────────────────────────────────────────
class _RecipePreviewPage extends StatefulWidget {
  final Recipe recipe;
  final bool isDark;
  final int servings;
  final void Function(Recipe) onAdded;

  const _RecipePreviewPage({
    required this.recipe, required this.isDark,
    required this.servings, required this.onAdded,
  });

  @override
  State<_RecipePreviewPage> createState() => _RecipePreviewPageState();
}

class _RecipePreviewPageState extends State<_RecipePreviewPage> {
  bool _editMode = false;
  bool _saving = false;
  bool _added = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  late int _editServings;
  late int _editDuration;
  late List<TextEditingController> _ingredientCtrls;
  late List<TextEditingController> _stepCtrls;

  @override
  void initState() {
    super.initState();
    _editServings = widget.servings;
    _editDuration = widget.recipe.durationMinutes;
    _titleCtrl = TextEditingController(text: widget.recipe.title);
    _descCtrl = TextEditingController(text: widget.recipe.description);
    _categoryCtrl = TextEditingController(text: widget.recipe.category ?? '');
    _ingredientCtrls = widget.recipe.ingredients
        .map((i) => TextEditingController(text: i)).toList();
    _stepCtrls = widget.recipe.steps
        .map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _categoryCtrl.dispose();
    for (final c in _ingredientCtrls) c.dispose();
    for (final c in _stepCtrls) c.dispose();
    super.dispose();
  }

  Recipe _buildEdited() => Recipe(
    id: widget.recipe.id,
    title: _titleCtrl.text.trim().isEmpty ? widget.recipe.title : _titleCtrl.text.trim(),
    category: _categoryCtrl.text.trim().isEmpty ? widget.recipe.category : _categoryCtrl.text.trim(),
    imageUrl: widget.recipe.imageUrl,
    durationMinutes: _editDuration,
    servings: _editServings,
    description: _descCtrl.text.trim(),
    ingredients: _ingredientCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
    steps: _stepCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
  );

  Future<void> _addRecipe() async {
    if (_saving || _added) return;
    setState(() => _saving = true);
    Recipe toAdd = _editMode ? _buildEdited() : widget.recipe.copyWith(servings: _editServings);
    if (AuthService.isLoggedIn) {
      try {
        toAdd = await RecipesService.saveRecipe(toAdd, isAiGenerated: true);
      } catch (e) {
        debugPrint('Erreur sauvegarde: $e');
      }
    }
    widget.onAdded(toAdd);
    if (mounted) {
      setState(() { _saving = false; _added = true; });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: surface, borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: textDark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_editMode ? '✏️ Modifier' : '👁️ Aperçu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _editMode = !_editMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _editMode
                            ? Colors.orange.withOpacity(0.15)
                            : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(_editMode ? Icons.visibility : Icons.edit_outlined,
                            size: 14,
                            color: _editMode ? Colors.orange : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(_editMode ? 'Aperçu' : 'Modifier',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: _editMode ? Colors.orange : AppColors.primary)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _editMode
                    ? _buildEditView(surface, textDark, textLight)
                    : _buildPreviewView(surface, textDark, textLight),
              ),
            ),

            // ── BOUTON AJOUTER ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _added ? null : _addRecipe,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_added ? Icons.check : Icons.add_circle_outline),
                  label: Text(
                    _added ? 'Recette ajoutée ✅'
                        : (_editMode ? 'Ajouter (version modifiée)' : 'Ajouter cette recette'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _added ? Colors.green : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── APERÇU ──────────────────────────────────
  Widget _buildPreviewView(Color surface, Color textDark, Color textLight) {
    final r = widget.recipe;
    final catColor = AppColors.categoryColor(r.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image du plat ────────────────────
        if (r.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              r.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                      color: catColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: Icon(Icons.restaurant, size: 48, color: catColor.withOpacity(0.4))),
              ),
            ),
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Icon(Icons.restaurant, size: 48, color: catColor.withOpacity(0.3))),
          ),
        const SizedBox(height: 14),

        if (r.category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(r.category!, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: catColor)),
          ),
        const SizedBox(height: 8),
        Text(r.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textDark)),
        const SizedBox(height: 6),
        Text(r.description, style: TextStyle(fontSize: 14, color: textLight, height: 1.5)),
        const SizedBox(height: 14),

        // Infos + ajustement personnes
        Row(children: [
          _infoChip(Icons.schedule, '${r.durationMinutes} min', surface, textDark),
          const SizedBox(width: 8),
          _infoChip(Icons.people, '$_editServings pers.', surface, textDark),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() { if (_editServings > 1) _editServings--; }),
            child: _smallBtn(Icons.remove),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() { if (_editServings < 20) _editServings++; }),
            child: _smallBtn(Icons.add),
          ),
        ]),

        const SizedBox(height: 22),
        _sectionTitle('🛒 Ingrédients', textDark),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
          ),
          child: Column(
            children: r.ingredients.asMap().entries.map((e) {
              final isLast = e.key == r.ingredients.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(
                      bottom: BorderSide(color: AppColors.cardShadow.withOpacity(0.4)))),
                child: Row(children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value, style: TextStyle(fontSize: 14, color: textDark))),
                ]),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 22),
        _sectionTitle('👨‍🍳 Préparation', textDark),
        const SizedBox(height: 10),
        ...r.steps.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28, alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text('${e.key + 1}', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(e.value,
                  style: TextStyle(fontSize: 14, color: textDark, height: 1.5))),
            ],
          ),
        )),
      ],
    );
  }

  // ── ÉDITION ─────────────────────────────────
  Widget _buildEditView(Color surface, Color textDark, Color textLight) {
    final dec = InputDecoration(
      filled: true, fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Titre', textLight),
        TextField(controller: _titleCtrl,
            style: TextStyle(color: textDark, fontWeight: FontWeight.w700), decoration: dec),
        const SizedBox(height: 12),
        _label('Catégorie', textLight),
        TextField(controller: _categoryCtrl, style: TextStyle(color: textDark), decoration: dec),
        const SizedBox(height: 12),
        _label('Description', textLight),
        TextField(controller: _descCtrl, style: TextStyle(color: textDark),
            maxLines: 3, decoration: dec),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Durée (min)', textLight),
              Row(children: [
                GestureDetector(
                    onTap: () => setState(() { if (_editDuration > 5) _editDuration -= 5; }),
                    child: _smallBtn(Icons.remove)),
                const SizedBox(width: 10),
                Text('$_editDuration', style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w900, color: textDark)),
                const SizedBox(width: 10),
                GestureDetector(
                    onTap: () => setState(() => _editDuration += 5),
                    child: _smallBtn(Icons.add)),
              ]),
            ],
          )),
          const SizedBox(width: 20),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Personnes', textLight),
              Row(children: [
                GestureDetector(
                    onTap: () => setState(() { if (_editServings > 1) _editServings--; }),
                    child: _smallBtn(Icons.remove)),
                const SizedBox(width: 10),
                Text('$_editServings', style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w900, color: textDark)),
                const SizedBox(width: 10),
                GestureDetector(
                    onTap: () => setState(() => _editServings++),
                    child: _smallBtn(Icons.add)),
              ]),
            ],
          )),
        ]),

        const SizedBox(height: 18),
        _editSection('🛒 Ingrédients', textLight, textDark,
            onAdd: () => setState(() => _ingredientCtrls.add(TextEditingController()))),
        ..._ingredientCtrls.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: e.value, style: TextStyle(color: textDark, fontSize: 14),
              decoration: dec.copyWith(
                  hintText: 'Ex: 200g de farine',
                  hintStyle: TextStyle(color: textLight)),
            )),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _ingredientCtrls.removeAt(e.key)),
              child: _deleteBtn(),
            ),
          ]),
        )),

        const SizedBox(height: 18),
        _editSection('👨‍🍳 Étapes', textLight, textDark,
            onAdd: () => setState(() => _stepCtrls.add(TextEditingController()))),
        ..._stepCtrls.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28, margin: const EdgeInsets.only(top: 10),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text('${e.key + 1}', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: e.value, style: TextStyle(color: textDark, fontSize: 14),
                maxLines: null,
                decoration: dec.copyWith(
                    hintText: "Décrivez l'étape...",
                    hintStyle: TextStyle(color: textLight)),
              )),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _stepCtrls.removeAt(e.key)),
                child: Container(
                  width: 32, height: 32, margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close, color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _label(String t, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
  );

  Widget _editSection(String title, Color textLight, Color textDark, {required VoidCallback onAdd}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textDark)),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.add, color: AppColors.primary, size: 14),
                  SizedBox(width: 4),
                  Text('Ajouter', style: TextStyle(
                      fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ),
      );

  Widget _deleteBtn() => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.close, color: Colors.red, size: 16),
  );

  Widget _smallBtn(IconData icon) => Container(
    width: 30, height: 30,
    decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: AppColors.primary, size: 16),
  );

  Widget _infoChip(IconData icon, String label, Color surface, Color textDark) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Row(children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textDark)),
        ]),
      );

  Widget _sectionTitle(String t, Color c) =>
      Text(t, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c));
}

class _Chip {
  final String label;
  final String query;
  const _Chip(this.label, this.query);
}