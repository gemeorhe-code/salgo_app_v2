import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

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

    final TextTheme baseTextTheme = _dmSansTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.orange,
        hintStyle: TextStyle(
          color: AppColors.textLight.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(color: AppColors.textLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.textLight,
          minimumSize: const Size(0, 56),
          textStyle: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.textLight,
          minimumSize: const Size(0, 56),
          textStyle: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.teal,
        contentTextStyle: GoogleFonts.dmSans(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.teal,
        selectedItemColor: AppColors.textLight,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textDark.withValues(alpha: 0.12),
      ),
    );
  }

  static TextTheme _dmSansTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: GoogleFonts.dmSans(textStyle: base.displayLarge),
      displayMedium: GoogleFonts.dmSans(textStyle: base.displayMedium),
      displaySmall: GoogleFonts.dmSans(textStyle: base.displaySmall),
      headlineLarge: GoogleFonts.dmSans(textStyle: base.headlineLarge),
      headlineMedium: GoogleFonts.dmSans(textStyle: base.headlineMedium),
      headlineSmall: GoogleFonts.dmSans(textStyle: base.headlineSmall),
      titleLarge: GoogleFonts.dmSans(textStyle: base.titleLarge),
      titleMedium: GoogleFonts.dmSans(textStyle: base.titleMedium),
      titleSmall: GoogleFonts.dmSans(textStyle: base.titleSmall),
      bodyLarge: GoogleFonts.dmSans(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.dmSans(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.dmSans(textStyle: base.bodySmall),
      labelLarge: GoogleFonts.dmSans(textStyle: base.labelLarge),
      labelMedium: GoogleFonts.dmSans(textStyle: base.labelMedium),
      labelSmall: GoogleFonts.dmSans(textStyle: base.labelSmall),
    );
  }

  static TextStyle display({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textDark,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
