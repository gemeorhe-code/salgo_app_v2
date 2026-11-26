import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color cream = Color(0xFFF5F5DC);
  static const Color orange = Color(0xFFEC8244);
  static const Color orangeDark = Color(0xFFD96E31);
  static const Color teal = Color(0xFF1B5A62);
  static const Color tealDark = Color(0xFF14454B);
  static const Color textDark = Color(0xFF2E2A26);
  static const Color textLight = Color(0xFFFFFDF7);
  static const Color white = Color(0xFFFFFFFF);

  static Color get border => textDark.withValues(alpha: 0.12);
  static Color get tealSoft => teal.withValues(alpha: 0.1);
  static Color get orangeSoft => orange.withValues(alpha: 0.14);
}
