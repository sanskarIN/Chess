import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../features/settings/application/settings_providers.dart';
import '../../../../features/settings/domain/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/board/square.dart';
import '../../domain/model/move.dart';
import '../../domain/model/piece.dart';
import '../../domain/model/position.dart';
import 'chess_piece_glyph.dart';

final class ChessBoard extends ConsumerWidget {
  const ChessBoard({
    required this.position,
    required this.selectedSquare,
    required this.legalMoves,
    required this.lastMove,
    required this.checkedKingSquare,
    required this.flipped,
    required this.onSquareTap,
    this.hintMove,
    this.enabled = true,
    super.key,
  });

  final Position position;
  final Square? selectedSquare;
  final List<Move> legalMoves;
  final Move? lastMove;
  final Square? checkedKingSquare;
  final Move? hintMove;
  final bool flipped;
  final ValueChanged<Square> onSquareTap;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(
      settingsControllerProvider.select((controller) => controller.settings),
    );
    final ChessBoardPalette palette = _palette(
      Theme.of(context).colorScheme,
      settings,
    );
    final bool showLegalMoves = settings.enabled(SettingFlag.showLegalMoves);
    final bool showLastMove = settings.enabled(SettingFlag.showLastMove);
    final bool showCheck = settings.enabled(SettingFlag.checkHighlight);
    final bool showCoordinates =
        settings.enabled(SettingFlag.boardCoordinates) &&
        settings.coordinatePosition != CoordinatePositionPreference.hidden;
    final Duration animationDuration =
        settings.enabled(SettingFlag.reducedMotion)
        ? Duration.zero
        : switch (settings.animationSpeed) {
            AnimationSpeedPreference.none => Duration.zero,
            AnimationSpeedPreference.fast => const Duration(milliseconds: 80),
            AnimationSpeedPreference.normal => const Duration(
              milliseconds: 150,
            ),
            AnimationSpeedPreference.slow => const Duration(milliseconds: 280),
          };
    return Semantics(
      container: true,
      label: AppLocalizations.of(context).chessBoard,
      child: Directionality(
        // App navigation mirrors for RTL locales, but chess files, ranks,
        // notation, and the explicit `flipped` orientation remain logical.
        textDirection: TextDirection.ltr,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Column(
                children: List<Widget>.generate(8, (int visualRank) {
                  return Expanded(
                    child: Row(
                      children: List<Widget>.generate(8, (int visualFile) {
                        final int rank = flipped ? visualRank : 7 - visualRank;
                        final int file = flipped ? 7 - visualFile : visualFile;
                        final Square square = Square.fromIndex(
                          (rank * 8) + file,
                        );
                        return Expanded(
                          child: _BoardSquare(
                            square: square,
                            piece: position.pieceAt(square),
                            isSelected: selectedSquare == square,
                            legalMove: showLegalMoves ? _moveTo(square) : null,
                            isCapture: showLegalMoves && _isCaptureOn(square),
                            isLastMove:
                                showLastMove &&
                                (lastMove?.from == square ||
                                    lastMove?.to == square),
                            isCheckedKing:
                                showCheck && checkedKingSquare == square,
                            isHintSource: hintMove?.from == square,
                            isHintTarget: hintMove?.to == square,
                            palette: palette,
                            legalMoveStyle: settings.legalMoveStyle,
                            animationDuration: animationDuration,
                            strongMarkers: settings.enabled(
                              SettingFlag.strongerLegalMoveMarkers,
                            ),
                            largeIndicators: settings.enabled(
                              SettingFlag.largerBoardIndicators,
                            ),
                            pieceTheme: settings.pieceTheme,
                            enabled: enabled,
                            showFileLabel: showCoordinates && visualRank == 7,
                            showRankLabel: showCoordinates && visualFile == 0,
                            onTap: () => onSquareTap(square),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Move? _moveTo(Square square) {
    for (final Move move in legalMoves) {
      if (move.to == square) {
        return move;
      }
    }
    return null;
  }

  bool _isCaptureOn(Square square) {
    final Move? move = _moveTo(square);
    return move != null && position.isCapture(move);
  }

  ChessBoardPalette _palette(ColorScheme colors, AppSettings settings) {
    if (settings.enabled(SettingFlag.colorBlindPalette)) {
      return const ChessBoardPalette(
        lightSquare: Color(0xFFF4E6C5),
        darkSquare: Color(0xFF3F6C9A),
        selected: Color(0xFFF2B134),
        lastMove: Color(0xFF8FC7D8),
        legalMove: Color(0xFF102A43),
        capture: Color(0xFFB14A00),
        check: Color(0xFF9C1C2B),
        hint: Color(0xFF7B2CBF),
      );
    }
    return switch (settings.boardTheme) {
      BoardThemePreference.classic => ChessBoardPalette.from(colors),
      BoardThemePreference.forest => const ChessBoardPalette(
        lightSquare: Color(0xFFE9DFC4),
        darkSquare: Color(0xFF3F6B4F),
        selected: Color(0xFFF4C95D),
        lastMove: Color(0xFF9CCB7E),
        legalMove: Color(0xFF173C2B),
        capture: Color(0xFF9D2438),
        check: Color(0xFFD63A4A),
        hint: Color(0xFF55C2FF),
      ),
      BoardThemePreference.ocean => const ChessBoardPalette(
        lightSquare: Color(0xFFDCECF2),
        darkSquare: Color(0xFF397C9A),
        selected: Color(0xFFFFCC66),
        lastMove: Color(0xFF80C7D9),
        legalMove: Color(0xFF083B66),
        capture: Color(0xFFB42336),
        check: Color(0xFFE23D4F),
        hint: Color(0xFF7C5CFC),
      ),
      BoardThemePreference.highContrast => const ChessBoardPalette(
        lightSquare: Color(0xFFFFFFFF),
        darkSquare: Color(0xFF111111),
        selected: Color(0xFFFFFF00),
        lastMove: Color(0xFF00FFFF),
        legalMove: Color(0xFF00C853),
        capture: Color(0xFFFF3D00),
        check: Color(0xFFFF1744),
        hint: Color(0xFF2979FF),
      ),
    };
  }
}

final class _BoardSquare extends StatelessWidget {
  const _BoardSquare({
    required this.square,
    required this.piece,
    required this.isSelected,
    required this.legalMove,
    required this.isCapture,
    required this.isLastMove,
    required this.isCheckedKing,
    required this.isHintSource,
    required this.isHintTarget,
    required this.palette,
    required this.legalMoveStyle,
    required this.animationDuration,
    required this.strongMarkers,
    required this.largeIndicators,
    required this.pieceTheme,
    required this.enabled,
    required this.showFileLabel,
    required this.showRankLabel,
    required this.onTap,
  });

  final Square square;
  final Piece? piece;
  final bool isSelected;
  final Move? legalMove;
  final bool isCapture;
  final bool isLastMove;
  final bool isCheckedKing;
  final bool isHintSource;
  final bool isHintTarget;
  final ChessBoardPalette palette;
  final LegalMoveStylePreference legalMoveStyle;
  final Duration animationDuration;
  final bool strongMarkers;
  final bool largeIndicators;
  final PieceThemePreference pieceTheme;
  final bool enabled;
  final bool showFileLabel;
  final bool showRankLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final Color base = square.isLight
        ? palette.lightSquare
        : palette.darkSquare;
    final Color background = isCheckedKing
        ? Color.alphaBlend(palette.check.withValues(alpha: 0.78), base)
        : isSelected
        ? Color.alphaBlend(palette.selected.withValues(alpha: 0.82), base)
        : isHintSource || isHintTarget
        ? Color.alphaBlend(palette.hint.withValues(alpha: 0.72), base)
        : isLastMove
        ? Color.alphaBlend(palette.lastMove.withValues(alpha: 0.68), base)
        : base;
    final String semantics = _semanticsLabel(strings, isCapture);
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : animationDuration;

    return Semantics(
      key: ValueKey<String>('square-${square.algebraic}'),
      button: enabled,
      enabled: enabled,
      selected: isSelected,
      label: semantics,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: duration,
          color: background,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double shortest = constraints.biggest.shortestSide;
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (legalMove != null)
                    Center(child: _legalMoveIndicator(shortest)),
                  Center(
                    child: AnimatedSwitcher(
                      duration: duration,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                      child: piece == null
                          ? const SizedBox.shrink()
                          : ChessPieceGlyph(
                              key: ValueKey<String>(
                                '${square.algebraic}-${piece!.fen}',
                              ),
                              piece: piece!,
                              size:
                                  shortest *
                                  (pieceTheme == PieceThemePreference.accessible
                                      ? 0.82
                                      : 0.76),
                              modern: pieceTheme == PieceThemePreference.modern,
                              highVisibility:
                                  pieceTheme == PieceThemePreference.accessible,
                            ),
                    ),
                  ),
                  if (showFileLabel)
                    PositionedDirectional(
                      end: 2,
                      bottom: 0,
                      child: Text(
                        String.fromCharCode(97 + square.file),
                        style: TextStyle(
                          fontSize: shortest * 0.17,
                          fontWeight: FontWeight.w800,
                          color: _coordinateColor,
                        ),
                      ),
                    ),
                  if (showRankLabel)
                    PositionedDirectional(
                      start: 2,
                      top: 0,
                      child: Text(
                        '${square.rank + 1}',
                        style: TextStyle(
                          fontSize: shortest * 0.17,
                          fontWeight: FontWeight.w800,
                          color: _coordinateColor,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color get _coordinateColor {
    return square.isLight ? const Color(0xFF33513E) : const Color(0xFFE9DFC4);
  }

  Widget _legalMoveIndicator(double shortest) {
    final double scale = largeIndicators ? 1.15 : 1;
    final double borderWidth = shortest * (strongMarkers ? 0.13 : 0.09);
    if (isCapture) {
      return Container(
        width: shortest * 0.82 * scale,
        height: shortest * 0.82 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.capture, width: borderWidth),
        ),
      );
    }
    return switch (legalMoveStyle) {
      LegalMoveStylePreference.dotAndRing => DecoratedBox(
        decoration: BoxDecoration(
          color: palette.legalMove,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(dimension: shortest * 0.22 * scale),
      ),
      LegalMoveStylePreference.square => Container(
        width: shortest * 0.48 * scale,
        height: shortest * 0.48 * scale,
        color: palette.legalMove,
      ),
      LegalMoveStylePreference.outline => Container(
        width: shortest * 0.58 * scale,
        height: shortest * 0.58 * scale,
        decoration: BoxDecoration(
          border: Border.all(color: palette.legalMove, width: borderWidth),
          borderRadius: BorderRadius.circular(shortest * 0.08),
        ),
      ),
    };
  }

  String _semanticsLabel(AppLocalizations strings, bool isCapture) {
    final String coordinate = square.algebraic.toUpperCase();
    final String occupant = piece == null
        ? strings.squareEmpty(coordinate)
        : strings.pieceOnSquare(
            localizedPieceName(strings, piece!),
            coordinate,
          );
    final List<String> states = <String>[
      if (isSelected) strings.selectedSquare,
      if (legalMove != null)
        isCapture ? strings.legalCapture : strings.legalMove,
      if (isLastMove) strings.lastMove,
      if (isCheckedKing) strings.inCheck,
      if (isHintSource) strings.hintSourceSquare,
      if (isHintTarget) strings.hintTargetSquare,
    ];
    return states.isEmpty
        ? occupant
        : strings.squareWithState(occupant, states.join(', '));
  }
}
