import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/model/piece.dart';
import '../../domain/model/piece_color.dart';
import '../../domain/model/piece_type.dart';

String chessPieceGlyph(Piece piece) {
  return switch ((piece.color, piece.type)) {
    (PieceColor.white, PieceType.king) => '♔',
    (PieceColor.white, PieceType.queen) => '♕',
    (PieceColor.white, PieceType.rook) => '♖',
    (PieceColor.white, PieceType.bishop) => '♗',
    (PieceColor.white, PieceType.knight) => '♘',
    (PieceColor.white, PieceType.pawn) => '♙',
    (PieceColor.black, PieceType.king) => '♚',
    (PieceColor.black, PieceType.queen) => '♛',
    (PieceColor.black, PieceType.rook) => '♜',
    (PieceColor.black, PieceType.bishop) => '♝',
    (PieceColor.black, PieceType.knight) => '♞',
    (PieceColor.black, PieceType.pawn) => '♟',
  };
}

String localizedPieceName(AppLocalizations strings, Piece piece) {
  final String color = piece.color == PieceColor.white
      ? strings.white
      : strings.black;
  final String type = switch (piece.type) {
    PieceType.pawn => strings.pawn,
    PieceType.knight => strings.knight,
    PieceType.bishop => strings.bishop,
    PieceType.rook => strings.rook,
    PieceType.queen => strings.queen,
    PieceType.king => strings.king,
  };
  return strings.coloredPiece(color, type);
}

final class ChessPieceGlyph extends StatelessWidget {
  const ChessPieceGlyph({required this.piece, required this.size, super.key});

  final Piece piece;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool white = piece.color == PieceColor.white;
    return Text(
      chessPieceGlyph(piece),
      style: TextStyle(
        fontSize: size,
        height: 1,
        color: white ? const Color(0xFFF8F5EC) : const Color(0xFF171B19),
        shadows: <Shadow>[
          Shadow(
            color: white ? const Color(0xB0000000) : const Color(0x8FFFFFFF),
            blurRadius: white ? 2 : 1,
          ),
        ],
      ),
    );
  }
}
