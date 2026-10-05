import 'package:flutter/material.dart';
import '../../presentation/providers/theme_provider.dart';

/// Semantic colors and Material 3 design tokens.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryDark = Color(0xFF4F46E5);
  static const secondary = Color(0xFF0EA5E9); // Sky
  static const accent = Color(0xFF8B5CF6); // Purple

  static const income = Color(0xFF10B981); // Emerald
  static const incomeBackground = Color(0xFFECFDF5);
  static const expense = Color(0xFFEF4444); // Crimson
  static const expenseBackground = Color(0xFFFEF2F2);

  static const warningAmber = Color(0xFFF59E0B);
  static const warningAmberLight = Color(0xFFFEF3C7);

  // Standard Slate Dark
  static const darkBackground = Color(0xFF0F172A); // Slate 900
  static const darkSurface = Color(0xFF1E293B); // Slate 800
  static const darkSurfaceVariant = Color(0xFF334155); // Slate 700

  // Pure AMOLED / OLED Black
  static const amoledBackground = Color(0xFF000000);
  static const amoledSurface = Color(0xFF111111);
  static const amoledSurfaceVariant = Color(0xFF1C1C1E);

  // Light Mode
  static const lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
}

/// Spacing scale (multiples of 4/8).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusFull = 999.0;
}

/// Unified dynamic ThemeData generator.
class AppTheme {
  AppTheme._();

  static ThemeData buildTheme({
    required AppThemeMode mode,
    required Color primaryColor,
  }) {
    switch (mode) {
      case AppThemeMode.light:
        return _buildLightTheme(primaryColor);
      case AppThemeMode.dark:
        return _buildDarkTheme(primaryColor, isAmoled: false);
      case AppThemeMode.amoled:
        return _buildDarkTheme(primaryColor, isAmoled: true);
    }
  }

  static ThemeData _buildLightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: primaryColor,
            );
          }
          return const TextStyle(fontSize: 12, color: Color(0xFF64748B));
        }),
      ),
    );
  }

  static ThemeData _buildDarkTheme(Color primaryColor, {required bool isAmoled}) {
    final bgColor = isAmoled ? AppColors.amoledBackground : AppColors.darkBackground;
    final surfaceColor = isAmoled ? AppColors.amoledSurface : AppColors.darkSurface;
    final borderColor = isAmoled ? const Color(0xFF222222) : const Color(0xFF334155);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: borderColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.white,
            );
          }
          return const TextStyle(fontSize: 12, color: Color(0xFF94A3B8));
        }),
      ),
    );
  }

  static ThemeData get lightTheme => buildTheme(mode: AppThemeMode.light, primaryColor: AppColors.primary);
  static ThemeData get darkTheme => buildTheme(mode: AppThemeMode.dark, primaryColor: AppColors.primary);
}
