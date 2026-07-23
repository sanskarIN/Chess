import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/model/piece.dart';
import '../../domain/model/piece_type.dart';
import 'chess_piece_glyph.dart';

final class CapturedPiecesPanel extends StatelessWidget {
  const CapturedPiecesPanel({
    required this.capturedByWhite,
    required this.capturedByBlack,
    this.showMaterialScore = true,
    super.key,
  });

  final List<Piece> capturedByWhite;
  final List<Piece> capturedByBlack;
  final bool showMaterialScore;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final int whiteMaterial = _material(capturedByWhite);
    final int blackMaterial = _material(capturedByBlack);
    return Semantics(
      container: true,
      label: strings.capturedPieces,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CapturedRow(
                label: strings.capturedBy(strings.white),
                pieces: capturedByWhite,
                materialAdvantage: showMaterialScore
                    ? whiteMaterial - blackMaterial
                    : 0,
              ),
              const Divider(height: DesignTokens.space16),
              _CapturedRow(
                label: strings.capturedBy(strings.black),
                pieces: capturedByBlack,
                materialAdvantage: showMaterialScore
                    ? blackMaterial - whiteMaterial
                    : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _material(List<Piece> pieces) {
    return pieces.fold<int>(
      0,
      (int total, Piece piece) =>
          total +
          switch (piece.type) {
            PieceType.pawn => 1,
            PieceType.knight || PieceType.bishop => 3,
            PieceType.rook => 5,
            PieceType.queen => 9,
            PieceType.king => 0,
          },
    );
  }
}

final class _CapturedRow extends StatelessWidget {
  const _CapturedRow({
    required this.label,
    required this.pieces,
    required this.materialAdvantage,
  });

  final String label;
  final List<Piece> pieces;
  final int materialAdvantage;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<Piece> sorted = List<Piece>.of(pieces)
      ..sort(
        (Piece first, Piece second) =>
            _sortValue(second.type).compareTo(_sortValue(first.type)),
      );
    final String pieceDescription = sorted.isEmpty
        ? strings.none
        : sorted
              .map((Piece piece) => localizedPieceName(strings, piece))
              .join(', ');
    final String score = materialAdvantage > 0 ? ' +$materialAdvantage' : '';
    return Semantics(
      label: '$label: $pieceDescription$score',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 1,
                children: sorted.isEmpty
                    ? <Widget>[
                        Text(
                          strings.none,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    : sorted
                          .map(
                            (Piece piece) =>
                                ChessPieceGlyph(piece: piece, size: 25),
                          )
                          .toList(growable: false),
              ),
            ),
          ),
          if (materialAdvantage > 0)
            Text(
              '+$materialAdvantage',
              style: Theme.of(context).textTheme.labelLarge,
            ),
        ],
      ),
    );
  }

  int _sortValue(PieceType type) {
    return switch (type) {
      PieceType.queen => 5,
      PieceType.rook => 4,
      PieceType.bishop => 3,
      PieceType.knight => 2,
      PieceType.pawn => 1,
      PieceType.king => 0,
    };
  }
}
