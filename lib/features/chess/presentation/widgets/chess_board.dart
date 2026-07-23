import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/board/square.dart';
import '../../domain/model/move.dart';
import '../../domain/model/piece.dart';
import '../../domain/model/position.dart';
import 'chess_piece_glyph.dart';

final class ChessBoard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ChessBoardPalette palette = ChessBoardPalette.from(
      Theme.of(context).colorScheme,
    );
    return Semantics(
      container: true,
      label: AppLocalizations.of(context).chessBoard,
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
                      final Square square = Square.fromIndex((rank * 8) + file);
                      return Expanded(
                        child: _BoardSquare(
                          square: square,
                          piece: position.pieceAt(square),
                          isSelected: selectedSquare == square,
                          legalMove: _moveTo(square),
                          isCapture: _isCaptureOn(square),
                          isLastMove:
                              lastMove?.from == square ||
                              lastMove?.to == square,
                          isCheckedKing: checkedKingSquare == square,
                          isHintSource: hintMove?.from == square,
                          isHintTarget: hintMove?.to == square,
                          palette: palette,
                          enabled: enabled,
                          showFileLabel: visualRank == 7,
                          showRankLabel: visualFile == 0,
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
        : const Duration(milliseconds: 150);

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
                    Center(
                      child: isCapture
                          ? Container(
                              width: shortest * 0.82,
                              height: shortest * 0.82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.capture,
                                  width: shortest * 0.09,
                                ),
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                color: palette.legalMove,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(
                                dimension: shortest * 0.22,
                              ),
                            ),
                    ),
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
                              size: shortest * 0.76,
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
