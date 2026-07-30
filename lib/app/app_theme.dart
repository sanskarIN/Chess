import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF285943);
  static const Color _lightSurface = Color(0xFFF8F4E8);
  static const Color _darkSurface = Color(0xFF121714);
  static const List<String> _fontFallbacks = <String>[
    'Noto Sans',
    'Noto Sans Devanagari',
    'Noto Sans Bengali',
    'Noto Sans Gujarati',
    'Noto Sans Gurmukhi',
    'Noto Sans Kannada',
    'Noto Sans Malayalam',
    'Noto Sans Oriya',
    'Noto Sans Tamil',
    'Noto Sans Telugu',
    'Noto Sans Arabic',
    'Noto Sans Meetei Mayek',
    'Noto Sans Ol Chiki',
  ];

  static ThemeData light() =>
      _theme(brightness: Brightness.light, surface: _lightSurface);

  static ThemeData dark() =>
      _theme(brightness: Brightness.dark, surface: _darkSurface);

  static ThemeData highContrast() {
    return _theme(
      brightness: Brightness.light,
      surface: Colors.white,
      contrastLevel: 1,
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color surface,
    double contrastLevel = 0.5,
  }) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      surface: surface,
      contrastLevel: contrastLevel,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      visualDensity: VisualDensity.standard,
      fontFamilyFallback: _fontFallbacks,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 450),
      ),
    );
  }
}
