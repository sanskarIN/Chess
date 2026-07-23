import '../board/square.dart';
import 'castling_rights.dart';
import 'move.dart';
import 'piece.dart';
import 'piece_color.dart';
import 'piece_type.dart';

final class Position {
  Position({
    required List<Piece?> board,
    required this.sideToMove,
    required this.castlingRights,
    required this.enPassantTarget,
    required this.halfmoveClock,
    required this.fullmoveNumber,
  }) : board = List<Piece?>.unmodifiable(board) {
    if (board.length != 64) {
      throw ArgumentError.value(board.length, 'board.length', 'Must be 64.');
    }
    if (halfmoveClock < 0) {
      throw ArgumentError.value(
        halfmoveClock,
        'halfmoveClock',
        'Must not be negative.',
      );
    }
    if (fullmoveNumber < 1) {
      throw ArgumentError.value(
        fullmoveNumber,
        'fullmoveNumber',
        'Must be at least one.',
      );
    }
  }

  final List<Piece?> board;
  final PieceColor sideToMove;
  final CastlingRights castlingRights;
  final Square? enPassantTarget;
  final int halfmoveClock;
  final int fullmoveNumber;

  Piece? pieceAt(Square square) => board[square.index];

  Iterable<MapEntry<Square, Piece>> pieces({PieceColor? color}) sync* {
    for (final Square square in Square.values) {
      final Piece? piece = pieceAt(square);
      if (piece != null && (color == null || piece.color == color)) {
        yield MapEntry<Square, Piece>(square, piece);
      }
    }
  }

  Square kingSquare(PieceColor color) {
    final List<MapEntry<Square, Piece>> kings = pieces(color: color)
        .where(
          (MapEntry<Square, Piece> entry) => entry.value.type == PieceType.king,
        )
        .toList(growable: false);
    if (kings.length != 1) {
      throw StateError(
        'Expected exactly one ${color.name} king, found ${kings.length}.',
      );
    }
    return kings.single.key;
  }

  bool isCapture(Move move) {
    final Piece? movingPiece = pieceAt(move.from);
    if (movingPiece == null) {
      return false;
    }
    if (pieceAt(move.to) != null) {
      return true;
    }
    return movingPiece.type == PieceType.pawn &&
        enPassantTarget == move.to &&
        move.from.file != move.to.file;
  }

  Piece? capturedPiece(Move move) {
    final Piece? directCapture = pieceAt(move.to);
    if (directCapture != null) {
      return directCapture;
    }
    final Piece? movingPiece = pieceAt(move.from);
    if (movingPiece?.type != PieceType.pawn ||
        enPassantTarget != move.to ||
        move.from.file == move.to.file) {
      return null;
    }
    final Square capturedSquare = Square.fromIndex(
      move.to.index - (movingPiece!.color.pawnRankDelta * 8),
    );
    return pieceAt(capturedSquare);
  }

  Position applyUnchecked(Move move) {
    if (move.from == move.to) {
      throw StateError('A move must change squares.');
    }

    final Piece? movingPiece = pieceAt(move.from);
    if (movingPiece == null) {
      throw StateError('No piece exists on ${move.from}.');
    }
    if (movingPiece.color != sideToMove) {
      throw StateError('The piece on ${move.from} is not the side to move.');
    }

    final Piece? targetPiece = pieceAt(move.to);
    if (targetPiece?.color == movingPiece.color) {
      throw StateError('A piece cannot capture its own side.');
    }
    if (targetPiece?.type == PieceType.king) {
      throw StateError('Kings are checked or mated, never captured.');
    }

    final bool reachesPromotionRank =
        movingPiece.type == PieceType.pawn &&
        move.to.rank == movingPiece.color.promotionRank;
    if (reachesPromotionRank && move.promotion == null) {
      throw StateError('A promotion piece is required.');
    }
    if (!reachesPromotionRank && move.promotion != null) {
      throw StateError('Promotion is allowed only on the final rank.');
    }

    final List<Piece?> nextBoard = List<Piece?>.of(board);
    nextBoard[move.from.index] = null;

    Piece? captured = targetPiece;
    Square captureSquare = move.to;
    final bool isEnPassant =
        movingPiece.type == PieceType.pawn &&
        enPassantTarget == move.to &&
        targetPiece == null &&
        move.from.file != move.to.file;
    if (isEnPassant) {
      captureSquare = Square.fromIndex(
        move.to.index - (movingPiece.color.pawnRankDelta * 8),
      );
      captured = nextBoard[captureSquare.index];
      if (captured == null ||
          captured.type != PieceType.pawn ||
          captured.color == movingPiece.color) {
        throw StateError('The en passant capture target is invalid.');
      }
      nextBoard[captureSquare.index] = null;
    }

    final bool isCastling =
        movingPiece.type == PieceType.king &&
        (move.to.file - move.from.file).abs() == 2;
    if (isCastling) {
      final bool kingSide = move.to.file > move.from.file;
      final Square rookFrom = Square.fromIndex(
        (movingPiece.color.homeRank * 8) + (kingSide ? 7 : 0),
      );
      final Square rookTo = Square.fromIndex(
        (movingPiece.color.homeRank * 8) + (kingSide ? 5 : 3),
      );
      final Piece? rook = nextBoard[rookFrom.index];
      if (rook != Piece(color: movingPiece.color, type: PieceType.rook)) {
        throw StateError('Castling requires the matching rook.');
      }
      nextBoard[rookFrom.index] = null;
      nextBoard[rookTo.index] = rook;
    }

    nextBoard[move.to.index] = move.promotion == null
        ? movingPiece
        : Piece(color: movingPiece.color, type: move.promotion!);

    CastlingRights nextCastlingRights = castlingRights;
    if (movingPiece.type == PieceType.king) {
      nextCastlingRights = nextCastlingRights.withoutColor(movingPiece.color);
    } else if (movingPiece.type == PieceType.rook) {
      nextCastlingRights = nextCastlingRights.withoutRookSquare(move.from);
    }
    if (captured?.type == PieceType.rook) {
      nextCastlingRights = nextCastlingRights.withoutRookSquare(captureSquare);
    }

    Square? nextEnPassantTarget;
    if (movingPiece.type == PieceType.pawn &&
        (move.to.rank - move.from.rank).abs() == 2) {
      nextEnPassantTarget = Square.fromIndex(
        (move.from.index + move.to.index) ~/ 2,
      );
    }

    final bool resetsHalfmove =
        movingPiece.type == PieceType.pawn || captured != null;

    return Position(
      board: nextBoard,
      sideToMove: sideToMove.opposite,
      castlingRights: nextCastlingRights,
      enPassantTarget: nextEnPassantTarget,
      halfmoveClock: resetsHalfmove ? 0 : halfmoveClock + 1,
      fullmoveNumber: fullmoveNumber + (sideToMove == PieceColor.black ? 1 : 0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Position ||
        other.sideToMove != sideToMove ||
        other.castlingRights != castlingRights ||
        other.enPassantTarget != enPassantTarget ||
        other.halfmoveClock != halfmoveClock ||
        other.fullmoveNumber != fullmoveNumber) {
      return false;
    }
    for (int index = 0; index < board.length; index++) {
      if (board[index] != other.board[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(board),
      sideToMove,
      castlingRights,
      enPassantTarget,
      halfmoveClock,
      fullmoveNumber,
    );
  }
}
