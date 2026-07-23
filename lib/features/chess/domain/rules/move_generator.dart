import '../board/square.dart';
import '../model/move.dart';
import '../model/piece.dart';
import '../model/piece_color.dart';
import '../model/piece_type.dart';
import '../model/position.dart';

final class MoveGenerator {
  const MoveGenerator();

  static const List<(int, int)> _knightOffsets = <(int, int)>[
    (1, 2),
    (2, 1),
    (2, -1),
    (1, -2),
    (-1, -2),
    (-2, -1),
    (-2, 1),
    (-1, 2),
  ];

  static const List<(int, int)> _kingOffsets = <(int, int)>[
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];

  static const List<(int, int)> _bishopDirections = <(int, int)>[
    (1, 1),
    (1, -1),
    (-1, -1),
    (-1, 1),
  ];

  static const List<(int, int)> _rookDirections = <(int, int)>[
    (1, 0),
    (0, -1),
    (-1, 0),
    (0, 1),
  ];

  List<Move> legalMoves(Position position, {Square? from}) {
    final List<Move> legal = <Move>[];
    final Iterable<MapEntry<Square, Piece>> pieces = from == null
        ? position.pieces(color: position.sideToMove)
        : _singlePiece(position, from);

    for (final MapEntry<Square, Piece> entry in pieces) {
      if (entry.value.color != position.sideToMove) {
        continue;
      }
      for (final Move move in pseudoLegalMovesFrom(position, entry.key)) {
        final Position next = position.applyUnchecked(move);
        if (!isInCheck(next, entry.value.color)) {
          legal.add(move);
        }
      }
    }
    return List<Move>.unmodifiable(legal);
  }

  bool isLegal(Position position, Move move) {
    return legalMoves(position, from: move.from).contains(move);
  }

  bool hasAnyLegalMove(Position position) {
    for (final MapEntry<Square, Piece> entry in position.pieces(
      color: position.sideToMove,
    )) {
      for (final Move move in pseudoLegalMovesFrom(position, entry.key)) {
        if (!isInCheck(position.applyUnchecked(move), entry.value.color)) {
          return true;
        }
      }
    }
    return false;
  }

  List<Move> pseudoLegalMovesFrom(Position position, Square from) {
    final Piece? piece = position.pieceAt(from);
    if (piece == null) {
      return const <Move>[];
    }
    final List<Move> moves = switch (piece.type) {
      PieceType.pawn => _pawnMoves(position, from, piece),
      PieceType.knight => _jumpMoves(position, from, piece, _knightOffsets),
      PieceType.bishop => _slidingMoves(
        position,
        from,
        piece,
        _bishopDirections,
      ),
      PieceType.rook => _slidingMoves(position, from, piece, _rookDirections),
      PieceType.queen => _slidingMoves(position, from, piece, <(int, int)>[
        ..._bishopDirections,
        ..._rookDirections,
      ]),
      PieceType.king => _kingMoves(position, from, piece),
    };
    return List<Move>.unmodifiable(moves);
  }

  bool isInCheck(Position position, PieceColor color) {
    return isSquareAttacked(
      position,
      position.kingSquare(color),
      byColor: color.opposite,
    );
  }

  bool isSquareAttacked(
    Position position,
    Square target, {
    required PieceColor byColor,
  }) {
    final int pawnSourceRankDelta = -byColor.pawnRankDelta;
    for (final int fileDelta in <int>[-1, 1]) {
      final Square? source = target.offset(
        fileDelta: fileDelta,
        rankDelta: pawnSourceRankDelta,
      );
      if (source != null &&
          position.pieceAt(source) ==
              Piece(color: byColor, type: PieceType.pawn)) {
        return true;
      }
    }

    for (final (int, int) offset in _knightOffsets) {
      final Square? source = target.offset(
        fileDelta: offset.$1,
        rankDelta: offset.$2,
      );
      if (source != null &&
          position.pieceAt(source) ==
              Piece(color: byColor, type: PieceType.knight)) {
        return true;
      }
    }

    for (final (int, int) offset in _kingOffsets) {
      final Square? source = target.offset(
        fileDelta: offset.$1,
        rankDelta: offset.$2,
      );
      if (source != null &&
          position.pieceAt(source) ==
              Piece(color: byColor, type: PieceType.king)) {
        return true;
      }
    }

    if (_isAttackedOnRay(
      position,
      target,
      byColor,
      _bishopDirections,
      const <PieceType>{PieceType.bishop, PieceType.queen},
    )) {
      return true;
    }
    return _isAttackedOnRay(
      position,
      target,
      byColor,
      _rookDirections,
      const <PieceType>{PieceType.rook, PieceType.queen},
    );
  }

  Iterable<MapEntry<Square, Piece>> _singlePiece(
    Position position,
    Square square,
  ) sync* {
    final Piece? piece = position.pieceAt(square);
    if (piece != null) {
      yield MapEntry<Square, Piece>(square, piece);
    }
  }

  List<Move> _pawnMoves(Position position, Square from, Piece pawn) {
    final List<Move> moves = <Move>[];
    final int direction = pawn.color.pawnRankDelta;
    final Square? oneForward = from.offset(fileDelta: 0, rankDelta: direction);
    if (oneForward != null && position.pieceAt(oneForward) == null) {
      _addPawnMove(moves, from, oneForward, pawn.color);
      if (from.rank == pawn.color.pawnStartRank) {
        final Square? twoForward = from.offset(
          fileDelta: 0,
          rankDelta: direction * 2,
        );
        if (twoForward != null && position.pieceAt(twoForward) == null) {
          moves.add(Move(from: from, to: twoForward));
        }
      }
    }

    for (final int fileDelta in <int>[-1, 1]) {
      final Square? target = from.offset(
        fileDelta: fileDelta,
        rankDelta: direction,
      );
      if (target == null) {
        continue;
      }
      final Piece? occupant = position.pieceAt(target);
      if (occupant != null &&
          occupant.color != pawn.color &&
          occupant.type != PieceType.king) {
        _addPawnMove(moves, from, target, pawn.color);
        continue;
      }
      if (position.enPassantTarget == target &&
          _hasCapturableEnPassantPawn(position, target, pawn.color)) {
        moves.add(Move(from: from, to: target));
      }
    }
    return moves;
  }

  void _addPawnMove(
    List<Move> moves,
    Square from,
    Square to,
    PieceColor color,
  ) {
    if (to.rank != color.promotionRank) {
      moves.add(Move(from: from, to: to));
      return;
    }
    for (final PieceType promotion in const <PieceType>[
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ]) {
      moves.add(Move(from: from, to: to, promotion: promotion));
    }
  }

  bool _hasCapturableEnPassantPawn(
    Position position,
    Square target,
    PieceColor capturingColor,
  ) {
    final Square capturedSquare = Square.fromIndex(
      target.index - (capturingColor.pawnRankDelta * 8),
    );
    return position.pieceAt(capturedSquare) ==
        Piece(color: capturingColor.opposite, type: PieceType.pawn);
  }

  List<Move> _jumpMoves(
    Position position,
    Square from,
    Piece piece,
    List<(int, int)> offsets,
  ) {
    final List<Move> moves = <Move>[];
    for (final (int, int) offset in offsets) {
      final Square? target = from.offset(
        fileDelta: offset.$1,
        rankDelta: offset.$2,
      );
      if (target == null) {
        continue;
      }
      final Piece? occupant = position.pieceAt(target);
      if (occupant == null ||
          (occupant.color != piece.color && occupant.type != PieceType.king)) {
        moves.add(Move(from: from, to: target));
      }
    }
    return moves;
  }

  List<Move> _slidingMoves(
    Position position,
    Square from,
    Piece piece,
    List<(int, int)> directions,
  ) {
    final List<Move> moves = <Move>[];
    for (final (int, int) direction in directions) {
      Square? target = from.offset(
        fileDelta: direction.$1,
        rankDelta: direction.$2,
      );
      while (target != null) {
        final Piece? occupant = position.pieceAt(target);
        if (occupant == null) {
          moves.add(Move(from: from, to: target));
        } else {
          if (occupant.color != piece.color &&
              occupant.type != PieceType.king) {
            moves.add(Move(from: from, to: target));
          }
          break;
        }
        target = target.offset(
          fileDelta: direction.$1,
          rankDelta: direction.$2,
        );
      }
    }
    return moves;
  }

  List<Move> _kingMoves(Position position, Square from, Piece king) {
    final List<Move> moves = _jumpMoves(position, from, king, _kingOffsets);
    if (from.file != 4 || from.rank != king.color.homeRank) {
      return moves;
    }

    final PieceColor opponent = king.color.opposite;
    if (isSquareAttacked(position, from, byColor: opponent)) {
      return moves;
    }
    if (_canCastle(position, king.color, kingSide: true)) {
      moves.add(
        Move(from: from, to: Square.fromIndex((king.color.homeRank * 8) + 6)),
      );
    }
    if (_canCastle(position, king.color, kingSide: false)) {
      moves.add(
        Move(from: from, to: Square.fromIndex((king.color.homeRank * 8) + 2)),
      );
    }
    return moves;
  }

  bool _canCastle(
    Position position,
    PieceColor color, {
    required bool kingSide,
  }) {
    final bool hasRight = kingSide
        ? position.castlingRights.canCastleKingSide(color)
        : position.castlingRights.canCastleQueenSide(color);
    if (!hasRight) {
      return false;
    }

    final int rank = color.homeRank;
    final Square rookSquare = Square.fromIndex((rank * 8) + (kingSide ? 7 : 0));
    if (position.pieceAt(rookSquare) !=
        Piece(color: color, type: PieceType.rook)) {
      return false;
    }

    final List<int> emptyFiles = kingSide ? <int>[5, 6] : <int>[1, 2, 3];
    for (final int file in emptyFiles) {
      if (position.pieceAt(Square.fromIndex((rank * 8) + file)) != null) {
        return false;
      }
    }

    final Square kingFrom = Square.fromIndex((rank * 8) + 4);
    final List<int> safeFiles = kingSide ? <int>[5, 6] : <int>[3, 2];
    for (final int file in safeFiles) {
      final Position kingAdvanced = position.applyUnchecked(
        Move(from: kingFrom, to: Square.fromIndex((rank * 8) + file)),
      );
      if (isInCheck(kingAdvanced, color)) {
        return false;
      }
    }
    return true;
  }

  bool _isAttackedOnRay(
    Position position,
    Square target,
    PieceColor byColor,
    List<(int, int)> directions,
    Set<PieceType> attackingTypes,
  ) {
    for (final (int, int) direction in directions) {
      Square? source = target.offset(
        fileDelta: direction.$1,
        rankDelta: direction.$2,
      );
      while (source != null) {
        final Piece? piece = position.pieceAt(source);
        if (piece != null) {
          if (piece.color == byColor && attackingTypes.contains(piece.type)) {
            return true;
          }
          break;
        }
        source = source.offset(
          fileDelta: direction.$1,
          rankDelta: direction.$2,
        );
      }
    }
    return false;
  }
}
