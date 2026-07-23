import 'move.dart';
import 'piece.dart';
import 'position.dart';

final class MoveRecord {
  const MoveRecord({
    required this.id,
    required this.ply,
    required this.move,
    required this.san,
    required this.positionBefore,
    required this.positionAfter,
    required this.capturedPiece,
  });

  final String id;
  final int ply;
  final Move move;
  final String san;
  final Position positionBefore;
  final Position positionAfter;
  final Piece? capturedPiece;
}
