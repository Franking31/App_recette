import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_localizations.dart';
import '../../../core/widgets/recipe_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../app.dart';
import '../../profile/profile_page.dart';
import '../data/dummy_data.dart';
import '../data/models/recipe.dart';
import '../pages/ai_assistant_page.dart';
import '../pages/add_recipe_page.dart';
import '../pages/shopping_list_page.dart';
import '../../../core/services/recipes_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favorites_service.dart';
import '../pages/search_page.dart';
import '../../../core/widgets/offline_banner.dart';

class RecipesListPage extends StatefulWidget {
  const RecipesListPage({super.key});

  @override
  State<RecipesListPage> createState() => _RecipesListPageState();
}

class _RecipesListPageState extends State<RecipesListPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'recent'; // recent | duration | rating
  int? _maxDuration;
  String? _difficulty;
  bool _showFilterSheet = false;
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
      if (mounted) {
        setState(() {
          // Recettes cloud en premier + dummy locales non dupliquées
          final cloudIds = cloudRecipes.map((r) => r.id).toSet();
          final localOnly = dummyRecipes
              .where((r) => !cloudIds.contains(r.id))
              .toList();
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
    var list = _recipes.where((r) {
      final matchSearch =
          r.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == null ||
          _selectedCategory == 'Tout' ||
          r.category == _selectedCategory;
      final matchDuration = _maxDuration == null ||
          r.durationMinutes <= _maxDuration!;
      return matchSearch && matchCat && matchDuration;
    }).toList();

    // Tri
    switch (_sortBy) {
      case 'duration':
        list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
      case 'alphabetical':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      default: // recent — garder ordre original
        break;
    }
    return list;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != null && _selectedCategory != 'Tout') count++;
    if (_maxDuration != null) count++;
    return count;
  }

  void _clearFilters() => setState(() {
    _selectedCategory = null;
    _maxDuration = null;
    _sortBy = 'recent';
  });

  void _toggleTheme() {
    final isDark = themeNotifier.value == ThemeMode.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'duration': return 'Durée ↑';
      case 'alphabetical': return 'A → Z';
      default: return 'Récentes';
    }
  }

  void _showSortSheet(BuildContext ctx, Color surface) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Trier par', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          for (final opt in [
            ('recent', '🆕', 'Plus récentes'),
            ('duration', '⏱️', 'Temps de préparation'),
            ('alphabetical', '🔤', 'Ordre alphabétique'),
          ])
            GestureDetector(
              onTap: () { setState(() => _sortBy = opt.$1); Navigator.pop(ctx); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _sortBy == opt.$1
                      ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sortBy == opt.$1
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.textLight.withOpacity(0.15),
                  ),
                ),
                child: Row(children: [
                  Text(opt.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(opt.$3, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _sortBy == opt.$1
                          ? AppColors.primary : AppColors.textDark)),
                  if (_sortBy == opt.$1) ...[
                    const Spacer(),
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 18),
                  ],
                ]),
              ),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAdvancedFilters(BuildContext ctx, Color surface, Color textMedium) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setInner) => Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              const Text('Filtres avancés', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              if (_activeFilterCount > 0)
                GestureDetector(
                  onTap: () { _clearFilters(); Navigator.pop(ctx2); },
                  child: const Text('Tout effacer',
                      style: TextStyle(fontSize: 13, color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 20),
            // Temps de préparation
            Align(alignment: Alignment.centerLeft,
              child: const Text('⏱️ Temps de préparation',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final d in [
                (null, 'Tous'), (15, '< 15min'), (30, '< 30min'), (60, '< 1h'),
              ])
                GestureDetector(
                  onTap: () => setInner(() => setState(() => _maxDuration = d.$1)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _maxDuration == d.$1
                          ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _maxDuration == d.$1
                            ? AppColors.primary
                            : AppColors.textLight.withOpacity(0.3),
                      ),
                    ),
                    child: Text(d.$2, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: _maxDuration == d.$1
                            ? Colors.white : AppColors.textDark)),
                  ),
                ),
            ]),
            const SizedBox(height: 20),
            // Catégorie
            Align(alignment: Alignment.centerLeft,
              child: const Text('🏷️ Catégorie',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final cat in _categories)
                GestureDetector(
                  onTap: () => setInner(() =>
                      setState(() => _selectedCategory = cat)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: (_selectedCategory ?? 'Tout') == cat
                          ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_selectedCategory ?? 'Tout') == cat
                            ? AppColors.primary
                            : AppColors.textLight.withOpacity(0.3),
                      ),
                    ),
                    child: Text(cat, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: (_selectedCategory ?? 'Tout') == cat
                            ? Colors.white : AppColors.textDark)),
                  ),
                ),
            ]),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(
                  'Voir \${_filtered.length} résultat\${_filtered.length > 1 ? "s" : ""}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 15),
                )),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
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
                    onRecipeAdded: (recipe) {
                      setState(() => _recipes.insert(0, recipe));
                      // Recharger depuis cloud pour avoir l'UUID correct
                      Future.delayed(const Duration(milliseconds: 500),
                          _loadCloudData);
                    },
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
            // ── BANNIÈRE HORS-LIGNE ────────────
            const OfflineBanner(),
            // ── HEADER ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  AppLogo.full(dark: isDark),
                  const Spacer(),
                  // Bouton recherche
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SearchPage())),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: const [BoxShadow(
                            color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton courses
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ShoppingListPage())),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: const [BoxShadow(
                            color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: const Center(child: Text('🛒',
                          style: TextStyle(fontSize: 18))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton profil
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfilePage())),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: const [BoxShadow(
                            color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Center(child: Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 20)),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    '${_recipes.length} ${AppLocalizations.t('recipes_count')}',
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
                    hintText: AppLocalizations.t('recipes_search_hint'),
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

            const SizedBox(height: 10),

            // ── FILTRES RAPIDES + BOUTON AVANCÉS ──
            SizedBox(
              height: 36,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  // Chips catégories
                  ..._categories.map((cat) {
                    final isSelected = (_selectedCategory ?? 'Tout') == cat;
                    final catColor = cat == 'Tout'
                        ? AppColors.primary
                        : AppColors.categoryColor(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? catColor : surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(color: divider, width: 1),
                            boxShadow: isSelected ? [
                              BoxShadow(color: catColor.withOpacity(0.3),
                                  blurRadius: 8, offset: const Offset(0, 3)),
                            ] : [],
                          ),
                          child: Text(cat, style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : textMedium)),
                        ),
                      ),
                    );
                  }),
                  // Chips durée rapide
                  ...[
                    ('⚡ < 15min', 15), ('🕐 < 30min', 30), ('🍳 < 1h', 60),
                  ].map((t) {
                    final isSelected = _maxDuration == t.$2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() =>
                            _maxDuration = isSelected ? null : t.$2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00BCD4) : surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(color: divider),
                          ),
                          child: Text(t.$1, style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : textMedium)),
                        ),
                      ),
                    );
                  }),
                  // Bouton filtres avancés
                  GestureDetector(
                    onTap: () => _showAdvancedFilters(context, surface, textMedium),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0
                            ? AppColors.primary : surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeFilterCount > 0
                              ? AppColors.primary : divider),
                      ),
                      child: Row(children: [
                        Icon(Icons.tune_rounded, size: 14,
                            color: _activeFilterCount > 0
                                ? Colors.white : textMedium),
                        const SizedBox(width: 4),
                        Text(
                          _activeFilterCount > 0
                              ? 'Filtres (\$_activeFilterCount)' : 'Filtres',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: _activeFilterCount > 0
                                  ? Colors.white : textMedium),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // ── BARRE RÉSULTATS + TRI ──────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(children: [
                Text('\${_filtered.length} recette\${_filtered.length > 1 ? "s" : ""}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: textLight)),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('✕ Réinitialiser',
                          style: TextStyle(fontSize: 10, color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => _showSortSheet(context, surface),
                  child: Row(children: [
                    Icon(Icons.swap_vert_rounded, size: 14, color: textLight),
                    const SizedBox(width: 4),
                    Text(_sortLabel, style: TextStyle(
                        fontSize: 12, color: textLight,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 4),

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
                          Text(AppLocalizations.t('recipes_empty'),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textLight)),
                          const SizedBox(height: 6),
                          Text('Essayez un autre mot-clé ou filtre',
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