import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5A4FCF);
  static const Color primaryLight = Color(0xFF8B7ED8);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF00CEC9);
  static const Color secondaryDark = Color(0xFF00B3AE);
  static const Color secondaryLight = Color(0xFF48E5E0);

  // Accent Colors
  static const Color accentColor = Color(0xFFFF7675);
  static const Color accentDark = Color(0xFFE84142);
  static const Color accentLight = Color(0xFFFF9F9E);

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color backgroundColorDark = Color(0xFF1A1A1A);
  static const Color surfaceColorDark = Color(0xFF2D2D2D);
  static const Color cardColorDark = Color(0xFF333333);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);

  // Status Colors
  static const Color successColor = Color(0xFF00D084);
  static const Color warningColor = Color(0xFFFDCB6E);
  static const Color errorColor = Color(0xFFE17055);
  static const Color infoColor = Color(0xFF74B9FF);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
