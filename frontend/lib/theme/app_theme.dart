import 'package:flutter/material.dart';

/// Colour palette from the design sheet (Primary / Accent / Background / Success).
class AppColors {
  static const primary = Color(0xFF7B1420); // deep maroon
  static const primaryDark = Color(0xFF5E0F18);
  static const accent = Color(0xFFC8102E); // red
  static const amber = Color(0xFFF2A93B);
  static const cream = Color(0xFFFFF8F0); // background
  static const success = Color(0xFF2E7D32);
  static const textDark = Color(0xFF1F1F2E);
  static const textGrey = Color(0xFF6B6B78);
  static const border = Color(0xFFEDE3DC);
  static const surface = Colors.white;

  // light tints
  static const primaryTint = Color(0xFFFBEAEC);
  static const accentTint = Color(0xFFFDECEE);
  static const amberTint = Color(0xFFFFF4E0);
  static const successTint = Color(0xFFE8F5E9);
  static const greyTint = Color(0xFFF4F1EF);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
