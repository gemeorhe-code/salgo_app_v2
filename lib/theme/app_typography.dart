import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme get textTheme {
    final TextTheme base = ThemeData.light().textTheme;
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        textStyle: base.displayLarge,
        fontSize: 40,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        textStyle: base.displayMedium,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        textStyle: base.displaySmall,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        textStyle: base.headlineLarge,
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        textStyle: base.headlineMedium,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        textStyle: base.headlineSmall,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.dmSans(
        textStyle: base.titleLarge,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.dmSans(
        textStyle: base.titleMedium,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.dmSans(
        textStyle: base.bodyLarge,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.dmSans(
        textStyle: base.bodyMedium,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.dmSans(
        textStyle: base.bodySmall,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.dmSans(
        textStyle: base.labelLarge,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: GoogleFonts.dmSans(
        textStyle: base.labelMedium,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: GoogleFonts.dmSans(
        textStyle: base.labelSmall,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static TextStyle display({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textDark,
    double? height,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle title({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textDark,
    double? height,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textDark,
    double? height,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle label({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textDark,
    double? height,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle caption({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textDark,
    double? height,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
