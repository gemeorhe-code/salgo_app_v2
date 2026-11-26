import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      onPrimary: AppColors.textLight,
      secondary: AppColors.orange,
      onSecondary: AppColors.textLight,
      surface: AppColors.cream,
      onSurface: AppColors.textDark,
      error: Colors.redAccent,
      onError: AppColors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.display(
          fontSize: 26,
          color: AppColors.textLight,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(0),
            bottom: Radius.circular(AppDimensions.radiusL),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.orange,
        hintStyle: AppTypography.body(
          color: AppColors.textLight.withValues(alpha: 0.85),
        ),
        labelStyle: AppTypography.body(color: AppColors.textLight),
        prefixIconColor: AppColors.textLight,
        suffixIconColor: AppColors.textLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: AppColors.textLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: AppTypography.caption(color: Colors.redAccent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.textLight,
          minimumSize: const Size(0, 56),
          textStyle: AppTypography.label(
            fontSize: 16,
            color: AppColors.textLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.textLight,
          minimumSize: const Size(0, 56),
          textStyle: AppTypography.label(
            fontSize: 16,
            color: AppColors.textLight,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.teal,
        contentTextStyle: AppTypography.body(color: AppColors.textLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.teal,
        selectedItemColor: AppColors.textLight,
        unselectedItemColor: AppColors.textLight.withValues(alpha: 0.72),
        selectedLabelStyle: AppTypography.label(
          fontSize: 11,
          color: AppColors.textLight,
        ),
        unselectedLabelStyle: AppTypography.caption(
          fontSize: 11,
          color: AppColors.textLight.withValues(alpha: 0.72),
        ),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }

  static TextStyle display({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textDark,
  }) {
    return AppTypography.display(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
