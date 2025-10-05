import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF0A6CF5);
  static const _accent = Color(0xFF22C55E);
  static const double _radius = 14;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      secondary: _accent,
      surfaceContainerHighest: const Color(0xFFF6F8FC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        titleTextStyle: _textTheme().titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        surfaceTintColor: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withOpacity(0.18),
        thickness: 1,
        space: 16,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: _outline(scheme),
        enabledBorder: _outline(scheme),
        focusedBorder: _outline(scheme, focused: true),
        errorBorder: _outline(scheme, error: true),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: scheme.outline.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor: scheme.surface.withOpacity(0.98),
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: _accent,
      surfaceContainerHighest: const Color(0xFF141821),
    );

    return light().copyWith(
      colorScheme: scheme,
      appBarTheme: light().appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      inputDecorationTheme: light().inputDecorationTheme.copyWith(
        fillColor: scheme.surfaceContainerHighest,
      ),
      snackBarTheme: light().snackBarTheme.copyWith(
        backgroundColor: scheme.surface.withOpacity(0.98),
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
    );
  }

  static OutlineInputBorder _outline(ColorScheme scheme, {bool focused=false, bool error=false}) {
    final color = error
        ? scheme.error
        : (focused ? scheme.primary : scheme.outline.withOpacity(0.35));
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: color, width: focused ? 1.6 : 1.1),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme().copyWith(
      headlineSmall: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(height: 1.25),
      bodyMedium: const TextStyle(height: 1.25),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
