import 'package:chess_master/features/chess/application/chess_game_controller.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/computer_player/application/computer_opponent_controller.dart';
import 'package:chess_master/features/computer_player/application/engine_service.dart';
import 'package:chess_master/features/computer_player/data/local_search_engine.dart';
import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computer playing White makes the first move automatically', () async {
    final GameSetup setup = GameSetup.computer(
      playerName: 'Ada',
      defaultPlayerName: 'You',
      computerName: 'Computer',
      sideChoice: PlayerSideChoice.black,
      timeControl: TimeControl.none,
      difficulty: ComputerDifficulty.beginner,
      hintsEnabled: false,
    );
    final ChessGameController matchController = ChessGameController(
      setup: setup,
    );
    final ComputerOpponentController computer = ComputerOpponentController(
      matchController: matchController,
      service: EngineService(
        ownedEngine: LocalSearchEngine(
          initialConfiguration: EngineConfiguration.forDifficulty(
            EngineDifficulty.beginner,
          ),
        ),
      ),
      opponentColor: PieceColor.white,
    );

    await computer.start();

    expect(matchController.game.moveRecords, hasLength(1));
    expect(matchController.position.sideToMove, PieceColor.black);
    expect(computer.isThinking, isFalse);
    expect(computer.failure, isNull);

    await computer.close();
    matchController.dispose();
  });
}
