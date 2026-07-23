import '../board/square.dart';
import 'piece_type.dart';

final class Move {
  const Move({required this.from, required this.to, this.promotion})
    : assert(
        promotion == null ||
            (promotion != PieceType.pawn && promotion != PieceType.king),
        'A pawn can promote only to a queen, rook, bishop, or knight.',
      );

  factory Move.fromUci(String value) {
    if (value.length != 4 && value.length != 5) {
      throw FormatException('Invalid UCI move: $value');
    }
    return Move(
      from: Square.fromAlgebraic(value.substring(0, 2)),
      to: Square.fromAlgebraic(value.substring(2, 4)),
      promotion: value.length == 5
          ? PieceType.fromPromotionLetter(value.substring(4, 5))
          : null,
    );
  }

  final Square from;
  final Square to;
  final PieceType? promotion;

  String get uci =>
      '${from.algebraic}${to.algebraic}'
      '${promotion?.fenLetter ?? ''}';

  @override
  bool operator ==(Object other) {
    return other is Move &&
        other.from == from &&
        other.to == to &&
        other.promotion == promotion;
  }

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => uci;
}
