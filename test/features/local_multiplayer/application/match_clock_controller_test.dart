import 'package:chess_master/features/chess/application/chess_game_controller.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/local_multiplayer/application/match_clock_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_monotonic_time_source.dart';

void main() {
  group('MatchClockController', () {
    test('follows moves, increment, undo, redo, and rematch', () {
      final FakeMonotonicTimeSource time = FakeMonotonicTimeSource();
      final ChessGameController match = ChessGameController(
        setup: _setup(
          const TimeControl(
            id: '5+2-test',
            initialSeconds: 5,
            incrementSeconds: 2,
          ),
        ),
      );
      final MatchClockController clock = MatchClockController(
        matchController: match,
        timeControl: match.setup.timeControl,
        timeSource: time,
        autoTick: false,
      );

      time.advance(const Duration(seconds: 2));
      clock.tick();
      _play(match, 'e2', 'e4');
      expect(clock.remaining(PieceColor.white), const Duration(seconds: 5));
      expect(clock.clock.activeColor, PieceColor.black);

      time.advance(const Duration(seconds: 1));
      _play(match, 'e7', 'e5');
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 6));

      match.undo();
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 5));
      match.redo();
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 6));

      match.restart();
      expect(clock.remaining(PieceColor.white), const Duration(seconds: 5));
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 5));

      clock.dispose();
      match.dispose();
    });

    test('declares timeout and pauses without charging hidden time', () {
      final FakeMonotonicTimeSource time = FakeMonotonicTimeSource();
      final ChessGameController match = ChessGameController(
        setup: _setup(const TimeControl(id: '3+0-test', initialSeconds: 3)),
      );
      final MatchClockController clock = MatchClockController(
        matchController: match,
        timeControl: match.setup.timeControl,
        timeSource: time,
        autoTick: false,
      );

      time.advance(const Duration(seconds: 1));
      clock.pause();
      time.advance(const Duration(seconds: 9));
      clock.tick();
      expect(clock.remaining(PieceColor.white), const Duration(seconds: 2));

      clock.resume();
      time.advance(const Duration(seconds: 2));
      clock.tick();
      expect(match.result?.reason, GameResultReason.timeout);
      expect(match.result?.winner, PieceColor.black);
      expect(clock.remaining(PieceColor.white), Duration.zero);

      clock.dispose();
      match.dispose();
    });
  });
}

GameSetup _setup(TimeControl timeControl) {
  return GameSetup.local(
    playerOneName: 'Ada',
    playerTwoName: 'Grace',
    defaultPlayerOneName: 'Player 1',
    defaultPlayerTwoName: 'Player 2',
    playerOneSide: PlayerSideChoice.white,
    timeControl: timeControl,
  );
}

void _play(ChessGameController controller, String from, String to) {
  controller
    ..selectSquare(Square.fromAlgebraic(from))
    ..selectSquare(Square.fromAlgebraic(to));
}
