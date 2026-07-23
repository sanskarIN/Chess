import 'package:chess_master/features/chess/application/chess_game_controller.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessGameController', () {
    test('selects a piece and delegates a legal move to ChessGame', () {
      final ChessGameController controller = ChessGameController(
        setup: _localSetup(),
      );

      final SquareSelectionResult selection = controller.selectSquare(
        Square.fromAlgebraic('e2'),
      );
      final SquareSelectionResult move = controller.selectSquare(
        Square.fromAlgebraic('e4'),
      );

      expect(selection.playedMove, isNull);
      expect(move.playedMove?.uci, 'e2e4');
      expect(controller.game.moveRecords.single.san, 'e4');
      expect(controller.position.sideToMove, PieceColor.black);
      expect(controller.canUndo, isTrue);
    });

    test('undo, redo, and branch replacement update view state', () {
      final ChessGameController controller = ChessGameController(
        setup: _localSetup(),
      );
      _play(controller, 'e2', 'e4');
      _play(controller, 'e7', 'e5');

      controller.undo();
      expect(controller.lastMove?.uci, 'e2e4');
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.lastMove?.uci, 'e7e5');

      controller.undo();
      _play(controller, 'c7', 'c5');
      expect(controller.lastMove?.uci, 'c7c5');
      expect(controller.canRedo, isFalse);
    });

    test('tracks captures by the player who made them', () {
      final ChessGameController controller = ChessGameController(
        setup: _localSetup(),
      );
      _play(controller, 'e2', 'e4');
      _play(controller, 'd7', 'd5');
      _play(controller, 'e4', 'd5');

      expect(controller.capturedBy(PieceColor.white), hasLength(1));
      expect(controller.capturedBy(PieceColor.black), isEmpty);
    });

    test('publishes resignation and draw results and can restart', () {
      final ChessGameController controller = ChessGameController(
        setup: _localSetup(),
      );

      controller.resignCurrentPlayer();
      expect(controller.result?.winner, PieceColor.black);
      expect(controller.result?.reason, GameResultReason.resignation);

      controller.restart();
      expect(controller.result, isNull);
      expect(controller.game.moveRecords, isEmpty);

      controller.offerAcceptedDraw();
      expect(controller.result?.isDraw, isTrue);
      expect(controller.result?.reason, GameResultReason.drawAgreement);
    });
  });
}

GameSetup _localSetup() {
  return GameSetup.local(
    playerOneName: '',
    playerTwoName: '',
    defaultPlayerOneName: 'Player 1',
    defaultPlayerTwoName: 'Player 2',
    playerOneSide: PlayerSideChoice.white,
    timeControl: TimeControl.none,
    rotateAfterMove: false,
  );
}

void _play(ChessGameController controller, String from, String to) {
  controller
    ..selectSquare(Square.fromAlgebraic(from))
    ..selectSquare(Square.fromAlgebraic(to));
}
