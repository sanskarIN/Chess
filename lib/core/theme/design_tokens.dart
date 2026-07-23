import 'package:flutter/material.dart';

abstract final class DesignTokens {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double radiusSmall = 12;
  static const double radiusMedium = 18;
  static const double radiusLarge = 28;
  static const double minimumTouchTarget = 48;
  static const double contentMaxWidth = 1120;

  static EdgeInsets pagePadding(double width) {
    if (width >= 1000) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
    if (width >= 600) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.all(20);
  }
}

final class ChessBoardPalette {
  const ChessBoardPalette({
    required this.lightSquare,
    required this.darkSquare,
    required this.selected,
    required this.lastMove,
    required this.legalMove,
    required this.capture,
    required this.check,
  });

  factory ChessBoardPalette.from(ColorScheme colors) {
    return ChessBoardPalette(
      lightSquare: colors.brightness == Brightness.light
          ? const Color(0xFFE9DFC4)
          : const Color(0xFFB8AD91),
      darkSquare: colors.brightness == Brightness.light
          ? const Color(0xFF4D745C)
          : const Color(0xFF33513E),
      selected: const Color(0xFFF4C95D),
      lastMove: const Color(0xFF9CCB7E),
      legalMove: const Color(0xFF244F3B),
      capture: const Color(0xFF9D2438),
      check: const Color(0xFFD63A4A),
    );
  }

  final Color lightSquare;
  final Color darkSquare;
  final Color selected;
  final Color lastMove;
  final Color legalMove;
  final Color capture;
  final Color check;
}
