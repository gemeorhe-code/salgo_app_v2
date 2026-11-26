import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

class OpenBadge extends StatelessWidget {
  const OpenBadge({
    super.key,
    required this.isOpen,
    this.openLabel = 'Abierto ahora',
    this.closedLabel = 'Cerrado',
  });

  final bool isOpen;
  final String openLabel;
  final String closedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.teal : AppColors.orangeDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.textLight),
          const SizedBox(width: AppDimensions.spaceXS),
          Text(
            isOpen ? openLabel : closedLabel,
            style: AppTypography.label(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
