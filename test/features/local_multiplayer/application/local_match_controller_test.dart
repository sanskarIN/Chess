import 'package:chess_master/features/chess/application/chess_game_controller.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/local_multiplayer/application/local_match_controller.dart';
import 'package:chess_master/features/local_multiplayer/domain/local_action_request.dart';
import 'package:chess_master/features/local_multiplayer/domain/local_match_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalMatchController', () {
    test('requires the opponent to approve undo and redo', () {
      final ChessGameController match = ChessGameController(setup: _setup());
      final LocalMatchController local = LocalMatchController(
        matchController: match,
        undoPolicy: LocalUndoPolicy.requireOpponentApproval,
      );
      _play(match, 'e2', 'e4');

      expect(local.requestUndo(), LocalRequestOutcome.approvalRequired);
      expect(local.pendingRequest?.type, LocalActionType.undo);
      local.declinePending();
      expect(match.game.ply, 1);

      local.requestUndo();
      local.approvePending();
      expect(match.game.ply, 0);

      expect(local.requestRedo(), LocalRequestOutcome.approvalRequired);
      local.approvePending();
      expect(match.game.ply, 1);

      local.dispose();
      match.dispose();
    });

    test('supports always-allow undo and approved draw offers', () {
      final ChessGameController match = ChessGameController(setup: _setup());
      final LocalMatchController local = LocalMatchController(
        matchController: match,
        undoPolicy: LocalUndoPolicy.alwaysAllow,
      );
      _play(match, 'e2', 'e4');

      expect(local.requestUndo(), LocalRequestOutcome.applied);
      expect(match.game.ply, 0);

      expect(local.requestDraw(), LocalRequestOutcome.approvalRequired);
      local.approvePending();
      expect(match.result?.reason, GameResultReason.drawAgreement);

      local.restart();
      expect(match.result, isNull);
      local.resignCurrentPlayer();
      expect(match.result?.reason, GameResultReason.resignation);

      local.dispose();
      match.dispose();
    });
  });
}

GameSetup _setup() {
  return GameSetup.local(
    playerOneName: 'Ada',
    playerTwoName: 'Grace',
    defaultPlayerOneName: 'Player 1',
    defaultPlayerTwoName: 'Player 2',
    playerOneSide: PlayerSideChoice.white,
    timeControl: TimeControl.none,
  );
}

void _play(ChessGameController controller, String from, String to) {
  controller
    ..selectSquare(Square.fromAlgebraic(from))
    ..selectSquare(Square.fromAlgebraic(to));
}
