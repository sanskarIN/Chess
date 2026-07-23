import 'package:chess_master/features/chess/domain/model/piece_color.dart';
import 'package:chess_master/features/local_multiplayer/domain/game_clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_monotonic_time_source.dart';

void main() {
  group('GameClock', () {
    test('uses monotonic elapsed time, increment, pause, and resume', () {
      final FakeMonotonicTimeSource time = FakeMonotonicTimeSource();
      final GameClock clock = GameClock(
        initialTime: const Duration(minutes: 3),
        increment: const Duration(seconds: 2),
        timeSource: time,
      )..start();

      time.advance(const Duration(seconds: 11));
      clock.synchronize();
      expect(clock.remaining(PieceColor.white), const Duration(seconds: 169));

      expect(
        clock.completeTurn(moveToken: '1:e2e4', movedColor: PieceColor.white),
        isTrue,
      );
      expect(clock.remaining(PieceColor.white), const Duration(seconds: 171));
      expect(clock.activeColor, PieceColor.black);

      time.advance(const Duration(seconds: 7));
      clock.pause();
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 173));
      time.advance(const Duration(minutes: 1));
      clock.synchronize();
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 173));

      clock.resume();
      time.advance(const Duration(seconds: 3));
      clock.synchronize();
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 170));
    });

    test('clamps at zero and reports exactly one expired side', () {
      final FakeMonotonicTimeSource time = FakeMonotonicTimeSource();
      final GameClock clock = GameClock(
        initialTime: const Duration(seconds: 5),
        increment: Duration.zero,
        timeSource: time,
      )..start();

      time.advance(const Duration(seconds: 8));

      expect(clock.synchronize(), PieceColor.white);
      expect(clock.remaining(PieceColor.white), Duration.zero);
      expect(clock.state, GameClockState.finished);
      expect(
        clock.completeTurn(moveToken: 'late', movedColor: PieceColor.white),
        isFalse,
      );
    });

    test('restores clock history for undo, redo, and branches', () {
      final FakeMonotonicTimeSource time = FakeMonotonicTimeSource();
      final GameClock clock = GameClock(
        initialTime: const Duration(seconds: 60),
        increment: Duration.zero,
        timeSource: time,
      )..start();

      time.advance(const Duration(seconds: 4));
      clock.completeTurn(moveToken: '1:e2e4', movedColor: PieceColor.white);
      time.advance(const Duration(seconds: 6));
      clock.completeTurn(moveToken: '2:e7e5', movedColor: PieceColor.black);

      expect(clock.remaining(PieceColor.white), const Duration(seconds: 56));
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 54));

      expect(clock.undo(), isTrue);
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 60));
      expect(clock.canRedoMove('2:e7e5'), isTrue);
      expect(clock.redo(), isTrue);
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 54));

      expect(clock.undo(), isTrue);
      time.advance(const Duration(seconds: 2));
      clock.completeTurn(moveToken: '2:c7c5', movedColor: PieceColor.black);
      expect(clock.canRedo, isFalse);
      expect(clock.remaining(PieceColor.black), const Duration(seconds: 58));
    });
  });
}
