import '../model/piece_type.dart';
import '../model/position.dart';
import '../notation/fen_codec.dart';
import 'move_generator.dart';

abstract final class Repetition {
  static String key(
    Position position, {
    MoveGenerator generator = const MoveGenerator(),
  }) {
    final bool hasLegalEnPassant =
        position.enPassantTarget != null &&
        generator
            .legalMoves(position)
            .any(
              (move) =>
                  move.to == position.enPassantTarget &&
                  position.pieceAt(move.from)?.type == PieceType.pawn &&
                  position.pieceAt(move.to) == null,
            );

    return <String>[
      FenCodec.encodeBoard(position),
      position.sideToMove.fen,
      position.castlingRights.fen,
      hasLegalEnPassant ? position.enPassantTarget!.algebraic : '-',
    ].join(' ');
  }
}
