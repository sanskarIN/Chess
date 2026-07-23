import '../board/square.dart';
import '../model/castling_rights.dart';
import '../model/piece.dart';
import '../model/piece_color.dart';
import '../model/piece_type.dart';
import '../model/position.dart';

abstract final class FenCodec {
  static const String standardInitialPosition =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static Position decode(String fen) {
    final List<String> fields = fen.trim().split(RegExp(r'\s+'));
    if (fields.length != 6) {
      throw const FormatException('FEN must contain exactly six fields.');
    }

    final List<Piece?> board = _decodeBoard(fields[0]);
    final PieceColor sideToMove = switch (fields[1]) {
      'w' => PieceColor.white,
      'b' => PieceColor.black,
      _ => throw FormatException('Invalid active color: ${fields[1]}'),
    };
    final CastlingRights castlingRights = CastlingRights.fromFen(fields[2]);
    final Square? enPassantTarget = fields[3] == '-'
        ? null
        : Square.tryParse(fields[3]);
    if (fields[3] != '-' && enPassantTarget == null) {
      throw FormatException('Invalid en passant target: ${fields[3]}');
    }

    final int? halfmoveClock = int.tryParse(fields[4]);
    final int? fullmoveNumber = int.tryParse(fields[5]);
    if (halfmoveClock == null || halfmoveClock < 0) {
      throw FormatException('Invalid halfmove clock: ${fields[4]}');
    }
    if (fullmoveNumber == null || fullmoveNumber < 1) {
      throw FormatException('Invalid fullmove number: ${fields[5]}');
    }

    final Position position = Position(
      board: board,
      sideToMove: sideToMove,
      castlingRights: castlingRights,
      enPassantTarget: enPassantTarget,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
    );
    _validateKings(position);
    _validateCastlingRights(position);
    _validateEnPassant(position);
    return position;
  }

  static String encode(Position position) {
    return <String>[
      encodeBoard(position),
      position.sideToMove.fen,
      position.castlingRights.fen,
      position.enPassantTarget?.algebraic ?? '-',
      position.halfmoveClock.toString(),
      position.fullmoveNumber.toString(),
    ].join(' ');
  }

  static String encodeBoard(Position position) {
    final StringBuffer board = StringBuffer();
    for (int rank = 7; rank >= 0; rank--) {
      int emptySquares = 0;
      for (int file = 0; file < 8; file++) {
        final Piece? piece = position.pieceAt(
          Square.fromIndex((rank * 8) + file),
        );
        if (piece == null) {
          emptySquares++;
          continue;
        }
        if (emptySquares > 0) {
          board.write(emptySquares);
          emptySquares = 0;
        }
        board.write(piece.fen);
      }
      if (emptySquares > 0) {
        board.write(emptySquares);
      }
      if (rank > 0) {
        board.write('/');
      }
    }
    return board.toString();
  }

  static List<Piece?> _decodeBoard(String value) {
    final List<String> ranks = value.split('/');
    if (ranks.length != 8) {
      throw const FormatException('A FEN board must contain eight ranks.');
    }

    final List<Piece?> board = List<Piece?>.filled(64, null);
    for (int fenRank = 0; fenRank < 8; fenRank++) {
      final int boardRank = 7 - fenRank;
      int file = 0;
      for (final int codeUnit in ranks[fenRank].codeUnits) {
        final String symbol = String.fromCharCode(codeUnit);
        final int? emptyCount = int.tryParse(symbol);
        if (emptyCount != null) {
          if (emptyCount < 1 || emptyCount > 8) {
            throw FormatException('Invalid empty-square count: $symbol');
          }
          file += emptyCount;
        } else {
          if (!RegExp(r'^[prnbqkPRNBQK]$').hasMatch(symbol)) {
            throw FormatException('Invalid FEN piece: $symbol');
          }
          if (file >= 8) {
            throw const FormatException(
              'A FEN rank contains too many squares.',
            );
          }
          board[(boardRank * 8) + file] = Piece.fromFen(symbol);
          file++;
        }
      }
      if (file != 8) {
        throw FormatException(
          'FEN rank ${8 - fenRank} contains $file squares instead of eight.',
        );
      }
    }
    return board;
  }

  static void _validateKings(Position position) {
    final List<Square> whiteKings = position
        .pieces(color: PieceColor.white)
        .where(
          (MapEntry<Square, Piece> entry) => entry.value.type == PieceType.king,
        )
        .map((MapEntry<Square, Piece> entry) => entry.key)
        .toList(growable: false);
    final List<Square> blackKings = position
        .pieces(color: PieceColor.black)
        .where(
          (MapEntry<Square, Piece> entry) => entry.value.type == PieceType.king,
        )
        .map((MapEntry<Square, Piece> entry) => entry.key)
        .toList(growable: false);
    if (whiteKings.length != 1 || blackKings.length != 1) {
      throw const FormatException(
        'A legal FEN position requires exactly one king per side.',
      );
    }
    final Square whiteKing = whiteKings.single;
    final Square blackKing = blackKings.single;
    if ((whiteKing.file - blackKing.file).abs() <= 1 &&
        (whiteKing.rank - blackKing.rank).abs() <= 1) {
      throw const FormatException('Kings cannot occupy adjacent squares.');
    }
  }

  static void _validateCastlingRights(Position position) {
    const Piece whiteKing = Piece(
      color: PieceColor.white,
      type: PieceType.king,
    );
    const Piece blackKing = Piece(
      color: PieceColor.black,
      type: PieceType.king,
    );
    const Piece whiteRook = Piece(
      color: PieceColor.white,
      type: PieceType.rook,
    );
    const Piece blackRook = Piece(
      color: PieceColor.black,
      type: PieceType.rook,
    );

    final CastlingRights rights = position.castlingRights;
    if ((rights.whiteKingSide || rights.whiteQueenSide) &&
        position.pieceAt(Square.fromAlgebraic('e1')) != whiteKing) {
      throw const FormatException(
        'White castling rights require a king on e1.',
      );
    }
    if ((rights.blackKingSide || rights.blackQueenSide) &&
        position.pieceAt(Square.fromAlgebraic('e8')) != blackKing) {
      throw const FormatException(
        'Black castling rights require a king on e8.',
      );
    }
    if (rights.whiteKingSide &&
        position.pieceAt(Square.fromAlgebraic('h1')) != whiteRook) {
      throw const FormatException(
        'White king-side rights require a rook on h1.',
      );
    }
    if (rights.whiteQueenSide &&
        position.pieceAt(Square.fromAlgebraic('a1')) != whiteRook) {
      throw const FormatException(
        'White queen-side rights require a rook on a1.',
      );
    }
    if (rights.blackKingSide &&
        position.pieceAt(Square.fromAlgebraic('h8')) != blackRook) {
      throw const FormatException(
        'Black king-side rights require a rook on h8.',
      );
    }
    if (rights.blackQueenSide &&
        position.pieceAt(Square.fromAlgebraic('a8')) != blackRook) {
      throw const FormatException(
        'Black queen-side rights require a rook on a8.',
      );
    }
  }

  static void _validateEnPassant(Position position) {
    final Square? target = position.enPassantTarget;
    if (target == null) {
      return;
    }
    final int requiredRank = position.sideToMove == PieceColor.white ? 5 : 2;
    if (target.rank != requiredRank || position.pieceAt(target) != null) {
      throw const FormatException('The en passant target is inconsistent.');
    }
    final PieceColor movedPawnColor = position.sideToMove.opposite;
    final Square pawnSquare = Square.fromIndex(
      target.index + (movedPawnColor.pawnRankDelta * 8),
    );
    if (position.pieceAt(pawnSquare) !=
        Piece(color: movedPawnColor, type: PieceType.pawn)) {
      throw const FormatException(
        'The en passant target has no matching pawn.',
      );
    }
  }
}
