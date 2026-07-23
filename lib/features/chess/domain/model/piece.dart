import 'piece_color.dart';
import 'piece_type.dart';

final class Piece {
  const Piece({required this.color, required this.type});

  factory Piece.fromFen(String value) {
    if (value.length != 1) {
      throw FormatException('Invalid FEN piece: $value');
    }
    final bool isWhite = value == value.toUpperCase();
    return Piece(
      color: isWhite ? PieceColor.white : PieceColor.black,
      type: PieceType.fromFenLetter(value),
    );
  }

  final PieceColor color;
  final PieceType type;

  String get fen {
    final String value = type.fenLetter;
    return color == PieceColor.white ? value.toUpperCase() : value;
  }

  @override
  bool operator ==(Object other) {
    return other is Piece && other.color == color && other.type == type;
  }

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => fen;
}
