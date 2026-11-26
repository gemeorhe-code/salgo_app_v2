import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.textDark.withValues(alpha: 0.1),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.tealDark.withValues(alpha: 0.18),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get header => [
    BoxShadow(
      color: AppColors.tealDark.withValues(alpha: 0.22),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get navigation => [
    BoxShadow(
      color: AppColors.tealDark.withValues(alpha: 0.16),
      blurRadius: 18,
      offset: const Offset(0, -6),
    ),
  ];
}
