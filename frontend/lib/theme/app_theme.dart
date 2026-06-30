import 'package:flutter/material.dart';

/// FluentAI design system — "Warm Violet & Peach" palette, rounded Varela Round type.
/// Calm, premium, friendly. Companion-centered, RTL Hebrew, light + dark.
class AppTheme {
  // Palette A — warm violet & peach.
  static const violet = Color(0xFF6C5CE7);
  static const violetLight = Color(0xFF8E7BFF);
  static const peach = Color(0xFFFF8FA3);
  static const ink = Color(0xFF2C2740);
  static const _bgLight = Color(0xFFF6F4FF);
  static const _bgDark = Color(0xFF141220);
  static const _surfaceDark = Color(0xFF1E1B2C);
  static const _onSurfaceDark = Color(0xFFEDEAF7);

  static const _font = 'VarelaRound';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(seedColor: violet, brightness: brightness).copyWith(
      primary: isLight ? violet : violetLight,
      onPrimary: Colors.white,
      secondary: peach,
      onSecondary: Colors.white,
      surface: isLight ? Colors.white : _surfaceDark,
      onSurface: isLight ? ink : _onSurfaceDark,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _font,
      scaffoldBackgroundColor: isLight ? _bgLight : _bgDark,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(fontFamily: _font, fontSize: 20, color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : _surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : _surfaceDark,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
      ),
    );
  }
}
