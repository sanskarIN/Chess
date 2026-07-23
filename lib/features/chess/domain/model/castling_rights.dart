import '../board/square.dart';
import 'piece_color.dart';

final class CastlingRights {
  const CastlingRights({
    required this.whiteKingSide,
    required this.whiteQueenSide,
    required this.blackKingSide,
    required this.blackQueenSide,
  });

  const CastlingRights.none()
    : whiteKingSide = false,
      whiteQueenSide = false,
      blackKingSide = false,
      blackQueenSide = false;

  factory CastlingRights.fromFen(String value) {
    if (value == '-') {
      return const CastlingRights.none();
    }
    final Set<String> symbols = value.split('').toSet();
    if (symbols.length != value.length ||
        symbols.any((String symbol) => !'KQkq'.contains(symbol))) {
      throw FormatException('Invalid castling rights: $value');
    }
    return CastlingRights(
      whiteKingSide: symbols.contains('K'),
      whiteQueenSide: symbols.contains('Q'),
      blackKingSide: symbols.contains('k'),
      blackQueenSide: symbols.contains('q'),
    );
  }

  final bool whiteKingSide;
  final bool whiteQueenSide;
  final bool blackKingSide;
  final bool blackQueenSide;

  bool canCastleKingSide(PieceColor color) {
    return color == PieceColor.white ? whiteKingSide : blackKingSide;
  }

  bool canCastleQueenSide(PieceColor color) {
    return color == PieceColor.white ? whiteQueenSide : blackQueenSide;
  }

  CastlingRights withoutColor(PieceColor color) {
    return color == PieceColor.white
        ? CastlingRights(
            whiteKingSide: false,
            whiteQueenSide: false,
            blackKingSide: blackKingSide,
            blackQueenSide: blackQueenSide,
          )
        : CastlingRights(
            whiteKingSide: whiteKingSide,
            whiteQueenSide: whiteQueenSide,
            blackKingSide: false,
            blackQueenSide: false,
          );
  }

  CastlingRights withoutRookSquare(Square square) {
    return CastlingRights(
      whiteKingSide: whiteKingSide && square.algebraic != 'h1',
      whiteQueenSide: whiteQueenSide && square.algebraic != 'a1',
      blackKingSide: blackKingSide && square.algebraic != 'h8',
      blackQueenSide: blackQueenSide && square.algebraic != 'a8',
    );
  }

  String get fen {
    final StringBuffer value = StringBuffer();
    if (whiteKingSide) {
      value.write('K');
    }
    if (whiteQueenSide) {
      value.write('Q');
    }
    if (blackKingSide) {
      value.write('k');
    }
    if (blackQueenSide) {
      value.write('q');
    }
    return value.isEmpty ? '-' : value.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is CastlingRights &&
        other.whiteKingSide == whiteKingSide &&
        other.whiteQueenSide == whiteQueenSide &&
        other.blackKingSide == blackKingSide &&
        other.blackQueenSide == blackQueenSide;
  }

  @override
  int get hashCode {
    return Object.hash(
      whiteKingSide,
      whiteQueenSide,
      blackKingSide,
      blackQueenSide,
    );
  }

  @override
  String toString() => fen;
}
