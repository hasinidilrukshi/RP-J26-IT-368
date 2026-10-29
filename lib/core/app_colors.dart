import 'package:flutter/material.dart';

/// Colors taken from the Ceylon Path "Home - Maroon" design.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF8B1A1A); // maroon
  static const Color primaryDark = Color(0xFF5E0B0B);
  static const Color primaryLight = Color(0xFFB23A3A);
  static const Color primarySoft = Color(0x1A8B1A1A); // 10% maroon
  static const Color accent = Color(0xFFE0A526); // gold (Kandyan accent)

  // Surfaces
  static const Color background = Color(0xFFFFF8F3); // cream page
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFEDE3DC);

  // Text
  static const Color textPrimary = Color(0xFF2B1A1A);
  static const Color textSecondary = Color(0xFF7A6A6A);
  static const Color textOnPrimary = Colors.white;

  // Severity levels
  static const Color severityLow = Color(0xFF2E9E5B);
  static const Color severityMedium = Color(0xFFE0A526);
  static const Color severityHigh = Color(0xFFE86A1C);
  static const Color severityCritical = Color(0xFFC62828);

  static const Color severityLowSoft = Color(0x1F2E9E5B);
  static const Color severityMediumSoft = Color(0x1FE0A526);
  static const Color severityHighSoft = Color(0x1FE86A1C);
  static const Color severityCriticalSoft = Color(0x1FC62828);

  static const Color shadow = Color(0x14000000);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return severityCritical;
      case 'high':
        return severityHigh;
      case 'medium':
        return severityMedium;
      default:
        return severityLow;
    }
  }

  static Color severitySoftColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return severityCriticalSoft;
      case 'high':
        return severityHighSoft;
      case 'medium':
        return severityMediumSoft;
      default:
        return severityLowSoft;
    }
  }
}
