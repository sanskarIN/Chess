import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/piece.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/chess/domain/model/piece_type.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessGame', () {
    test('prevents illegal moves and records legal SAN history', () {
      final ChessGame game = ChessGame(gameId: 'game-1');

      expect(() => game.play(Move.fromUci('e2e5')), throwsStateError);
      final first = game.play(Move.fromUci('e2e4'));
      final second = game.play(Move.fromUci('e7e5'));

      expect(first.id, 'game-1:1');
      expect(first.san, 'e4');
      expect(second.san, 'e5');
      expect(game.ply, 2);
    });

    test('supports undo, redo, and branch replacement', () {
      final ChessGame game = ChessGame(gameId: 'game-undo')
        ..play(Move.fromUci('e2e4'))
        ..play(Move.fromUci('e7e5'));

      expect(game.undo().move, Move.fromUci('e7e5'));
      expect(game.canRedo, isTrue);
      expect(game.redo().move, Move.fromUci('e7e5'));

      game.undo();
      game.play(Move.fromUci('c7c5'));

      expect(game.canRedo, isFalse);
      expect(game.moveRecords.map((record) => record.san), <String>[
        'e4',
        'c5',
      ]);
    });

    test('restores a saved game by validating every move', () {
      final ChessGame restored = ChessGame.restore(
        gameId: 'restored',
        initialPosition: FenCodec.decode(FenCodec.standardInitialPosition),
        moves: <Move>[
          Move.fromUci('e2e4'),
          Move.fromUci('c7c5'),
          Move.fromUci('g1f3'),
        ],
      );

      expect(restored.ply, 3);
      expect(restored.moveRecords.map((record) => record.san), <String>[
        'e4',
        'c5',
        'Nf3',
      ]);
      expect(
        () => ChessGame.restore(
          gameId: 'invalid-restore',
          initialPosition: FenCodec.decode(FenCodec.standardInitialPosition),
          moves: <Move>[Move.fromUci('e2e5')],
        ),
        throwsStateError,
      );
    });

    test('tracks captured pieces including en passant', () {
      final ChessGame game = ChessGame(
        gameId: 'game-captures',
        initialPosition: FenCodec.decode('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2'),
      )..play(Move.fromUci('e5d6'));

      expect(game.capturedPieces, <Piece>[
        const Piece(color: PieceColor.black, type: PieceType.pawn),
      ]);
    });

    test('detects checkmate and stalemate', () {
      final ChessGame checkmate = ChessGame(
        gameId: 'mate',
        initialPosition: FenCodec.decode('7k/6Q1/6K1/8/8/8/8/8 b - - 0 1'),
      );
      final ChessGame stalemate = ChessGame(
        gameId: 'stalemate',
        initialPosition: FenCodec.decode('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
      );

      expect(
        checkmate.result,
        const GameResult.whiteWin(GameResultReason.checkmate),
      );
      expect(
        stalemate.result,
        const GameResult.draw(GameResultReason.stalemate),
      );
    });

    test('detects threefold repetition', () {
      final ChessGame game = ChessGame(gameId: 'repetition');
      for (final String uci in <String>[
        'g1f3',
        'g8f6',
        'f3g1',
        'f6g8',
        'g1f3',
        'g8f6',
        'f3g1',
        'f6g8',
      ]) {
        game.play(Move.fromUci(uci));
      }

      expect(
        game.result,
        const GameResult.draw(GameResultReason.threefoldRepetition),
      );
    });

    test('detects the fifty-move rule', () {
      final ChessGame game = ChessGame(
        gameId: 'fifty-move',
        initialPosition: FenCodec.decode('4k2r/8/8/8/8/8/8/R3K3 w - - 99 1'),
      )..play(Move.fromUci('a1a2'));

      expect(
        game.result,
        const GameResult.draw(GameResultReason.fiftyMoveRule),
      );
    });

    test('detects conventional insufficient material positions', () {
      for (final String fen in <String>[
        '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
        '4k3/8/8/8/8/8/8/2B1K3 w - - 0 1',
        '4k3/8/8/8/8/8/8/2N1K3 w - - 0 1',
        '4kb2/8/8/8/8/8/8/2B1K3 w - - 0 1',
      ]) {
        final ChessGame game = ChessGame(
          gameId: 'material-${fen.hashCode}',
          initialPosition: FenCodec.decode(fen),
        );
        expect(
          game.result,
          const GameResult.draw(GameResultReason.insufficientMaterial),
          reason: fen,
        );
      }
    });

    test('supports draw agreement, resignation, and timeout', () {
      final ChessGame draw = ChessGame(gameId: 'draw')..agreeDraw();
      final ChessGame resignation = ChessGame(gameId: 'resign')
        ..resign(PieceColor.black);
      final ChessGame timeout = ChessGame(
        gameId: 'timeout',
        initialPosition: FenCodec.decode('4k3/8/8/8/8/8/8/R3K3 b - - 0 1'),
      )..declareTimeout(PieceColor.black);

      expect(
        draw.result,
        const GameResult.draw(GameResultReason.drawAgreement),
      );
      expect(
        resignation.result,
        const GameResult.whiteWin(GameResultReason.resignation),
      );
      expect(
        timeout.result,
        const GameResult.whiteWin(GameResultReason.timeout),
      );
    });

    test('timeout is a draw when the opponent cannot possibly mate', () {
      final ChessGame game = ChessGame(
        gameId: 'timeout-draw',
        initialPosition: FenCodec.decode('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'),
      )..declareTimeout(PieceColor.white);

      expect(game.result, const GameResult.draw(GameResultReason.timeout));
    });
  });
}
