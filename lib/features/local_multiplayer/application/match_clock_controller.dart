import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../chess/application/chess_game_controller.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/move_record.dart';
import '../../chess/domain/model/piece_color.dart';
import '../domain/game_clock.dart';
import '../domain/monotonic_time_source.dart';

typedef MatchClockTimerFactory =
    Timer Function(Duration interval, void Function() callback);

final class MatchClockController extends ChangeNotifier {
  MatchClockController({
    required this.matchController,
    required TimeControl timeControl,
    MonotonicTimeSource? timeSource,
    MatchClockTimerFactory? timerFactory,
    bool autoTick = true,
  }) : clock = GameClock(
         initialTime: Duration(seconds: timeControl.initialSeconds),
         increment: Duration(seconds: timeControl.incrementSeconds),
         timeSource: timeSource ?? StopwatchTimeSource(),
       ),
       _gameId = matchController.game.gameId,
       _observedPly = matchController.game.ply {
    matchController.addListener(_handleMatchChanged);
    clock.start(activeColor: matchController.position.sideToMove);
    if (clock.enabled && autoTick) {
      _timer = (timerFactory ?? _defaultTimerFactory)(
        const Duration(milliseconds: 200),
        tick,
      );
    }
  }

  final ChessGameController matchController;
  final GameClock clock;
  late String _gameId;
  int _observedPly;
  Timer? _timer;
  bool _disposed = false;

  Duration remaining(PieceColor color) => clock.remaining(color);
  bool get hasClock => clock.enabled;
  bool get isPaused => clock.isPaused;

  void tick() {
    if (_disposed || !clock.enabled || matchController.result != null) {
      return;
    }
    final PieceColor? expired = clock.synchronize();
    if (expired != null && matchController.result == null) {
      matchController.declareTimeout(expired);
    }
    notifyListeners();
  }

  void pause() {
    clock.pause();
    notifyListeners();
  }

  void resume() {
    if (matchController.result != null) {
      return;
    }
    clock.resume();
    notifyListeners();
  }

  void _handleMatchChanged() {
    if (_disposed) {
      return;
    }
    if (_gameId != matchController.game.gameId) {
      _gameId = matchController.game.gameId;
      _observedPly = matchController.game.ply;
      clock.restart(activeColor: matchController.position.sideToMove);
      notifyListeners();
      return;
    }

    final int currentPly = matchController.game.ply;
    while (_observedPly > currentPly) {
      clock.undo();
      _observedPly--;
    }
    while (_observedPly < currentPly) {
      final MoveRecord record = matchController.game.moveRecords[_observedPly];
      final String token = '${record.id}:${record.move.uci}';
      if (clock.canRedoMove(token)) {
        clock.redo();
      } else {
        clock.completeTurn(
          moveToken: token,
          movedColor: record.positionBefore.sideToMove,
        );
      }
      _observedPly++;
    }
    if (matchController.result != null) {
      clock.stop();
    }
    notifyListeners();
  }

  static Timer _defaultTimerFactory(
    Duration interval,
    void Function() callback,
  ) {
    return Timer.periodic(interval, (_) => callback());
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _timer?.cancel();
    matchController.removeListener(_handleMatchChanged);
    super.dispose();
  }
}
