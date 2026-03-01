import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/recipe_card.dart';
import '../../../core/services/recipes_service.dart';
import '../data/models/recipe.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════
//  SEARCH PAGE — Recherche recettes cloud
//  • Recherche temps réel (titre + ingrédients)
//  • Filtres : catégorie, durée max
//  • Historique des 5 dernières recherches
// ═══════════════════════════════════════════

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  // État recherche
  List<Recipe> _results = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;

  // Filtres
  String? _selectedCategory;
  int? _maxDuration; // null = pas de limite
  List<String> _categories = [];

  // Historique
  List<String> _history = [];

  static const _historyKey = 'search_history';
  static const _durationOptions = [
    {'label': 'Tous', 'value': null},
    {'label': '≤ 15 min', 'value': 15},
    {'label': '≤ 30 min', 'value': 30},
    {'label': '≤ 60 min', 'value': 60},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadCategories();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Historique ───────────────────────────
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [
      query,
      ..._history.where((h) => h != query),
    ].take(5).toList();
    await prefs.setStringList(_historyKey, updated);
    setState(() => _history = updated);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() => _history = []);
  }

  // ── Catégories ───────────────────────────
  Future<void> _loadCategories() async {
    final cats = await RecipesService.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  // ── Recherche ────────────────────────────
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search();
    });
  }

  Future<void> _search({String? forcedQuery}) async {
    final query = forcedQuery ?? _searchCtrl.text.trim();

    // Besoin d'au moins un critère
    final hasQuery = query.isNotEmpty;
    final hasFilter = _selectedCategory != null || _maxDuration != null;
    if (!hasQuery && !hasFilter) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }

    setState(() { _loading = true; _error = null; _hasSearched = true; });

    try {
      final results = await RecipesService.searchRecipes(
        query: query,
        category: _selectedCategory,
        maxDuration: _maxDuration,
      );
      if (mounted) setState(() { _results = results; _loading = false; });
      if (hasQuery) _saveToHistory(query);
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyHistory(String query) {
    _searchCtrl.text = query;
    _searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length));
    _search(forcedQuery: query);
  }

  void _clearQuery() {
    _searchCtrl.clear();
    setState(() { _results = []; _hasSearched = false; _error = null; });
  }

  // ── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barre de recherche ──────────
            _buildSearchBar(surface, textDark, textLight, isDark),

            // ── Filtres ─────────────────────
            _buildFilters(surface, textDark, textLight, divider, isDark),

            // ── Contenu ─────────────────────
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : !_hasSearched
                          ? _buildHistory(textDark, textLight, divider, isDark)
                          : _results.isEmpty
                              ? _buildEmpty(textLight)
                              : _buildResults(textLight),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre de recherche ────────────────────
  Widget _buildSearchBar(Color surface, Color textDark, Color textLight, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Retour
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: textDark),
            ),
          ),
          const SizedBox(width: 10),

          // Champ de recherche
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: _onQueryChanged,
                onSubmitted: (v) => _search(),
                style: TextStyle(fontSize: 15, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Titre, ingrédient...',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textLight, size: 18),
                          onPressed: _clearQuery,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtres ────────────────────────────────
  Widget _buildFilters(Color surface, Color textDark, Color textLight,
      Color divider, bool isDark) {
    return Column(
      children: [
        // Durée
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _durationOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final opt = _durationOptions[i];
              final val = opt['value'] as int?;
              final isSelected = _maxDuration == val;
              return GestureDetector(
                onTap: () {
                  setState(() => _maxDuration = val);
                  if (_hasSearched || _searchCtrl.text.isNotEmpty) _search();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                  ),
                  child: Text(opt['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : textLight,
                      )),
                ),
              );
            },
          ),
        ),

        // Catégories (si disponibles)
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = i == 0 ? null : _categories[i - 1];
                final label = cat ?? 'Toutes';
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    if (_hasSearched || _searchCtrl.text.isNotEmpty) _search();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.85)
                          : surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
                    ),
                    child: Text(label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.textDark : textLight,
                        )),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        Divider(height: 1, color: divider),
      ],
    );
  }

  // ── Historique ────────────────────────────
  Widget _buildHistory(Color textDark, Color textLight, Color divider, bool isDark) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Recherchez par titre\nou par ingrédient',
                textAlign: TextAlign.center,
                style: TextStyle(color: textLight, fontSize: 15, height: 1.5)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Text('Recherches récentes',
                    style: TextStyle(color: textDark,
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: _clearHistory,
                  child: Text('Effacer',
                      style: TextStyle(color: AppColors.primary,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          ..._history.map((h) => ListTile(
                dense: true,
                leading: Icon(Icons.history_rounded, color: textLight, size: 18),
                title: Text(h,
                    style: TextStyle(color: textDark,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.north_west_rounded, color: textLight, size: 14),
                onTap: () => _applyHistory(h),
              )),
        ],
      ),
    );
  }

  // ── Résultats ─────────────────────────────
  Widget _buildResults(Color textLight) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '${_results.length} résultat${_results.length > 1 ? 's' : ''}',
              style: TextStyle(color: textLight,
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => RecipeCard(recipe: _results[i]),
            childCount: _results.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  // ── États vides/erreur/loading ─────────────
  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Recherche en cours...',
                style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );

  Widget _buildEmpty(Color textLight) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Aucune recette trouvée',
                style: TextStyle(color: textLight,
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Essayez d\'autres mots-clés\nou modifiez les filtres',
                textAlign: TextAlign.center,
                style: TextStyle(color: textLight, fontSize: 13, height: 1.5)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Erreur de recherche',
                  style: TextStyle(color: AppColors.textDark,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(_error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}