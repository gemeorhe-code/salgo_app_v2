import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceM,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(icon, color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title(fontSize: 15),
                ),
              ),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      fontSize: 12,
                      color: AppColors.textDark.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              const SizedBox(width: AppDimensions.spaceS),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.teal,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
