import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/recipe_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../app.dart';
import '../data/dummy_data.dart';
import '../data/models/recipe.dart';
import '../pages/ai_assistant_page.dart';
import '../pages/add_recipe_page.dart';
import '../../../core/services/recipes_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favorites_service.dart';

class RecipesListPage extends StatefulWidget {
  const RecipesListPage({super.key});

  @override
  State<RecipesListPage> createState() => _RecipesListPageState();
}

class _RecipesListPageState extends State<RecipesListPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedCategory;
  late List<Recipe> _recipes;
  late AnimationController _fabController;
  bool _cloudLoading = false;

  @override
  void initState() {
    super.initState();
    _recipes = List.from(dummyRecipes);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _loadCloudData();
  }

  Future<void> _loadCloudData() async {
    if (!AuthService.isLoggedIn) return;
    setState(() => _cloudLoading = true);
    try {
      // Charger recettes cloud + favoris en parallèle
      final results = await Future.wait([
        RecipesService.getMyRecipes(),
        FavoritesService.getFavorites(),
      ]);
      final cloudRecipes = results[0] as List<Recipe>;
      if (cloudRecipes.isNotEmpty && mounted) {
        setState(() {
          // Fusionner : recettes cloud + recettes locales non dupliquées
          final cloudIds = cloudRecipes.map((r) => r.id).toSet();
          final localOnly = _recipes.where((r) => !cloudIds.contains(r.id)).toList();
          _recipes = [...cloudRecipes, ...localOnly];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement cloud: $e');
    } finally {
      if (mounted) setState(() => _cloudLoading = false);
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = _recipes
        .where((r) => r.category != null)
        .map((r) => r.category!)
        .toSet()
        .toList();
    return ['Tout', ...cats];
  }

  List<Recipe> get _filtered {
    return _recipes.where((r) {
      final matchSearch =
          r.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == null ||
          _selectedCategory == 'Tout' ||
          r.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  void _toggleTheme() {
    final isDark = themeNotifier.value == ThemeMode.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final textMedium = isDark ? AppColors.darkTextLight : AppColors.textMedium;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecipePage(
                    onRecipeAdded: (recipe) =>
                        setState(() => _recipes.insert(0, recipe)),
                  ),
                ),
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ScaleTransition(
            scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiAssistantPage()),
              ),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 22)),
                    Text('IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AppLogo.full(dark: isDark),
                  const Spacer(),
                  // Toggle thème jour/nuit
                  GestureDetector(
                    onTap: _toggleTheme,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 54,
                      height: 30,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.8)
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: isDark
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isDark ? '🌙' : '☀️',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_recipes.length} recettes disponibles',
                    style: TextStyle(
                      fontSize: 13,
                      color: textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_cloudLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── BARRE DE RECHERCHE ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une recette...',
                    hintStyle: TextStyle(color: textLight, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: textLight, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── FILTRES ────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = (_selectedCategory ?? 'Tout') == cat;
                  final catColor = cat == 'Tout'
                      ? AppColors.primary
                      : AppColors.categoryColor(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor : surface,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: divider, width: 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: catColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : textMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── LISTE ──────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('😕',
                                  style: TextStyle(fontSize: 36)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Aucune recette trouvée',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textLight)),
                          const SizedBox(height: 6),
                          Text('Essayez un autre mot-clé',
                              style: TextStyle(
                                  fontSize: 13, color: textLight)),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 900 ? 3 : width > 600 ? 2 : 2;
                        final childAspectRatio = width > 900 ? 0.82 : 0.80;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) =>
                              RecipeCard(recipe: _filtered[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}