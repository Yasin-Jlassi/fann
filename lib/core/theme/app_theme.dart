import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F12);
  static const Color surface = Color(0xFF18181F);
  static const Color surfaceVariant = Color(0xFF24242F);
  static const Color primary = Color(0xFFFF3366);
  static const Color primaryLight = Color(0xFFFF5E8A);
  static const Color secondary = Color(0xFF7047EB);
  static const Color textPrimary = Color(0xFFF3F3F5);
  static const Color textSecondary = Color(0xFFA0A0AB);
  static const Color textMuted = Color(0xFF6B6B76);
  static const Color accent = Color(0xFF00E5FF);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceVariant,
        thumbColor: AppColors.textPrimary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayColor: AppColors.primary.withValues(alpha: 0.2),
        trackHeight: 3.5,
      ),
    );
  }
}
