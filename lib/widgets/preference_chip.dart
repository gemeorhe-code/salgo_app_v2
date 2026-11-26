import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

class PreferenceChip extends StatelessWidget {
  const PreferenceChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceS,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.orange,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: selected
              ? Border.all(color: AppColors.textLight, width: 2)
              : null,
          boxShadow: selected ? AppShadows.floating : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textLight, size: 20),
            const SizedBox(width: AppDimensions.spaceS),
            Text(
              label,
              style: AppTypography.label(
                fontSize: 15,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
