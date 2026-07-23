import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/piece.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/chess/domain/model/piece_type.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/chess/domain/rules/move_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MoveGenerator generator = MoveGenerator();

  group('special move rules', () {
    test('allows both castling sides only when paths are safe', () {
      final openPosition = FenCodec.decode(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      );
      final List<Move> openMoves = generator.legalMoves(
        openPosition,
        from: Square.fromAlgebraic('e1'),
      );

      expect(openMoves, contains(Move.fromUci('e1g1')));
      expect(openMoves, contains(Move.fromUci('e1c1')));

      final attackedPath = FenCodec.decode(
        'r3k2r/8/8/8/2b5/8/8/R3K2R w KQkq - 0 1',
      );
      final List<Move> attackedMoves = generator.legalMoves(
        attackedPath,
        from: Square.fromAlgebraic('e1'),
      );

      expect(attackedMoves, isNot(contains(Move.fromUci('e1g1'))));
      expect(attackedMoves, contains(Move.fromUci('e1c1')));
    });

    test('castling moves the rook and permanently clears king rights', () {
      final position = FenCodec.decode('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final next = position.applyUnchecked(Move.fromUci('e1g1'));

      expect(next.pieceAt(Square.fromAlgebraic('h1')), isNull);
      expect(
        next.pieceAt(Square.fromAlgebraic('f1')),
        const Piece(color: PieceColor.white, type: PieceType.rook),
      );
      expect(
        next.pieceAt(Square.fromAlgebraic('g1')),
        const Piece(color: PieceColor.white, type: PieceType.king),
      );
      expect(next.castlingRights.whiteKingSide, isFalse);
      expect(next.castlingRights.whiteQueenSide, isFalse);
    });

    test('executes en passant and removes the passed pawn', () {
      final position = FenCodec.decode('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2');
      final Move move = Move.fromUci('e5d6');

      expect(generator.isLegal(position, move), isTrue);
      final next = position.applyUnchecked(move);
      expect(next.pieceAt(Square.fromAlgebraic('d5')), isNull);
      expect(
        next.pieceAt(Square.fromAlgebraic('d6')),
        const Piece(color: PieceColor.white, type: PieceType.pawn),
      );
    });

    test('rejects en passant when it would expose the king', () {
      final position = FenCodec.decode('k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');

      expect(generator.isLegal(position, Move.fromUci('e5d6')), isFalse);
    });

    test('generates all four promotion choices', () {
      final position = FenCodec.decode('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
      final List<Move> promotions = generator
          .legalMoves(position, from: Square.fromAlgebraic('a7'))
          .where((Move move) => move.to == Square.fromAlgebraic('a8'))
          .toList(growable: false);

      expect(promotions, hasLength(4));
      expect(promotions.map((Move move) => move.promotion).toSet(), <PieceType>{
        PieceType.queen,
        PieceType.rook,
        PieceType.bishop,
        PieceType.knight,
      });
    });

    test('a pinned rook may move only along the pin line', () {
      final position = FenCodec.decode('4r1k1/8/8/8/8/8/4R3/4K3 w - - 0 1');
      final List<Move> moves = generator.legalMoves(
        position,
        from: Square.fromAlgebraic('e2'),
      );

      expect(moves, isNot(contains(Move.fromUci('e2d2'))));
      expect(moves, contains(Move.fromUci('e2e8')));
    });

    test('double check permits king moves only', () {
      final position = FenCodec.decode('4r1k1/8/8/8/1b6/8/8/4K2R w K - 0 1');
      final List<Move> moves = generator.legalMoves(position);

      expect(generator.isInCheck(position, PieceColor.white), isTrue);
      expect(
        moves.every((Move move) => move.from == Square.fromAlgebraic('e1')),
        isTrue,
      );
    });
  });
}
