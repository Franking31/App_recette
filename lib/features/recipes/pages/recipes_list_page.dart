import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/recipe_card.dart';
import '../data/dummy_data.dart';
import '../data/models/recipe.dart';
import '../pages/ai_assistant_page.dart';
import '../pages/add_recipe_page.dart';

class RecipesListPage extends StatefulWidget {
  const RecipesListPage({super.key});

  @override
  State<RecipesListPage> createState() => _RecipesListPageState();
}

class _RecipesListPageState extends State<RecipesListPage> {
  String _searchQuery = '';
  String? _selectedCategory;
  late List<Recipe> _recipes;

  @override
  void initState() {
    super.initState();
    _recipes = List.from(dummyRecipes);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton + Ajouter une recette
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddRecipePage(
                  onRecipeAdded: (recipe) {
                    setState(() => _recipes.insert(0, recipe));
                  },
                ),
              ),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton IA
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAssistantPage()),
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8604A), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8604A).withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🤖', style: TextStyle(fontSize: 22)),
                  Text(
                    'IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👨‍🍳 Mes Recettes',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_recipes.length} recettes disponibles',
                    style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une recette...',
                        hintStyle: TextStyle(color: AppColors.textLight),
                        prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = (_selectedCategory ?? 'Tout') == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('😕', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Aucune recette trouvée',
                              style: TextStyle(fontSize: 16, color: AppColors.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) => RecipeCard(recipe: _filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}