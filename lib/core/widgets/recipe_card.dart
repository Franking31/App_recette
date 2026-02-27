import 'package:flutter/material.dart';
import '../../features/recipes/data/models/recipe.dart';
import '../../features/recipes/pages/recipe_detail_page.dart';
import '../constants/app_colors.dart';

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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Row(
          children: [
            // ── IMAGE ────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: recipe.imageUrl != null
                  ? Image.network(
                      recipe.imageUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(catColor),
                    )
                  : _placeholder(catColor),
            ),

            // ── CONTENU ───────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge catégorie coloré
                    if (recipe.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          recipe.category!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Infos temps + personnes
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: catColor),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.durationMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people_rounded,
                            size: 13, color: catColor),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings} pers.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── FLÈCHE ────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: catColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color catColor) => Container(
        width: 110,
        height: 110,
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
        child: Icon(Icons.restaurant_rounded,
            color: catColor.withValues(alpha: 0.8), size: 36),
      );
}