import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class IngredientTile extends StatelessWidget {
  final String ingredient;
  final bool checked;
  final VoidCallback? onTap;

  const IngredientTile({
    super.key,
    required this.ingredient,
    this.checked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.textLight,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ingredient,
                style: TextStyle(
                  fontSize: 14,
                  color: checked ? AppColors.textLight : AppColors.textDark,
                  decoration:
                      checked ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}