import 'package:flutter/material.dart';
import '../../features/recipes/data/models/recipe.dart';
import '../../features/recipes/pages/recipe_detail_page.dart';
import '../constants/app_colors.dart';

// ═══════════════════════════════════════════
//  RECIPE CARD — Version grille (carrée)
// ═══════════════════════════════════════════

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final textDark = isDark ? AppColors.darkTextDark : AppColors.textDark;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final catColor = AppColors.categoryColor(recipe.category);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE ────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(catColor),
                      )
                    : _placeholder(catColor),
              ),
            ),

            // ── CONTENU ───────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge catégorie
                    if (recipe.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: catColor.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          recipe.category!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Titre
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Infos
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 11, color: catColor),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.durationMinutes}m',
                          style: TextStyle(fontSize: 11, color: textLight,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people_rounded, size: 11, color: catColor),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.servings}p',
                          style: TextStyle(fontSize: 11, color: textLight,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color catColor) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              catColor.withValues(alpha: 0.3),
              catColor.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(Icons.restaurant_rounded,
              color: catColor.withValues(alpha: 0.8), size: 40),
        ),
      );
}