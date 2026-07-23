import '../model/move.dart';
import '../model/piece.dart';
import '../model/piece_type.dart';
import '../model/position.dart';
import '../rules/move_generator.dart';

final class SanCodec {
  const SanCodec({this.generator = const MoveGenerator()});

  final MoveGenerator generator;

  String encode(Position position, Move move) {
    if (!generator.isLegal(position, move)) {
      throw StateError('Cannot encode an illegal move: ${move.uci}');
    }
    final Piece movingPiece = position.pieceAt(move.from)!;
    final bool isCastling =
        movingPiece.type == PieceType.king &&
        (move.to.file - move.from.file).abs() == 2;

    final StringBuffer san = StringBuffer();
    if (isCastling) {
      san.write(move.to.file == 6 ? 'O-O' : 'O-O-O');
    } else {
      san.write(movingPiece.type.sanLetter);
      if (movingPiece.type != PieceType.pawn) {
        san.write(_disambiguation(position, move, movingPiece));
      }

      final bool isCapture = position.isCapture(move);
      if (movingPiece.type == PieceType.pawn && isCapture) {
        san.write(String.fromCharCode(97 + move.from.file));
      }
      if (isCapture) {
        san.write('x');
      }
      san.write(move.to.algebraic);
      if (move.promotion != null) {
        san
          ..write('=')
          ..write(move.promotion!.sanLetter);
      }
    }

    final Position next = position.applyUnchecked(move);
    if (generator.isInCheck(next, next.sideToMove)) {
      san.write(generator.hasAnyLegalMove(next) ? '+' : '#');
    }
    return san.toString();
  }

  Move decode(Position position, String value) {
    final String normalized = _normalize(value);
    final List<Move> matches = generator
        .legalMoves(position)
        .where((Move move) => _normalize(encode(position, move)) == normalized)
        .toList(growable: false);
    if (matches.length != 1) {
      throw FormatException(
        matches.isEmpty
            ? 'No legal move matches SAN: $value'
            : 'Ambiguous SAN move: $value',
      );
    }
    return matches.single;
  }

  String _disambiguation(Position position, Move move, Piece movingPiece) {
    final List<Move> contenders = generator
        .legalMoves(position)
        .where(
          (Move candidate) =>
              candidate != move &&
              candidate.to == move.to &&
              position.pieceAt(candidate.from)?.type == movingPiece.type,
        )
        .toList(growable: false);
    if (contenders.isEmpty) {
      return '';
    }

    final bool sharesFile = contenders.any(
      (Move contender) => contender.from.file == move.from.file,
    );
    final bool sharesRank = contenders.any(
      (Move contender) => contender.from.rank == move.from.rank,
    );
    final String file = String.fromCharCode(97 + move.from.file);
    final String rank = (move.from.rank + 1).toString();
    if (!sharesFile) {
      return file;
    }
    if (!sharesRank) {
      return rank;
    }
    return '$file$rank';
  }

  String _normalize(String value) {
    return value
        .trim()
        .replaceAll('0-0-0', 'O-O-O')
        .replaceAll('0-0', 'O-O')
        .replaceAll(RegExp(r'[!?]+$'), '');
  }
}
