import '../../chess/domain/model/piece_color.dart';
import 'monotonic_time_source.dart';

enum GameClockState { ready, running, paused, finished }

final class GameClockSnapshot {
  const GameClockSnapshot({
    required this.whiteRemaining,
    required this.blackRemaining,
    required this.activeColor,
    required this.state,
    required this.expiredColor,
  });

  final Duration whiteRemaining;
  final Duration blackRemaining;
  final PieceColor? activeColor;
  final GameClockState state;
  final PieceColor? expiredColor;
}

final class GameClock {
  GameClock({
    required this.initialTime,
    required this.increment,
    required this.timeSource,
  }) : assert(!initialTime.isNegative),
       assert(!increment.isNegative),
       _whiteRemaining = initialTime,
       _blackRemaining = initialTime;

  final Duration initialTime;
  final Duration increment;
  final MonotonicTimeSource timeSource;
  final List<_ClockTurnRecord> _records = <_ClockTurnRecord>[];

  late Duration _whiteRemaining;
  late Duration _blackRemaining;
  Duration _lastReading = Duration.zero;
  GameClockState _state = GameClockState.ready;
  PieceColor? _activeColor;
  PieceColor? _expiredColor;
  GameClockSnapshot? _turnStart;
  int _cursor = 0;

  bool get enabled => initialTime > Duration.zero;
  GameClockState get state => _state;
  PieceColor? get activeColor => _activeColor;
  PieceColor? get expiredColor => _expiredColor;
  bool get isRunning => _state == GameClockState.running;
  bool get isPaused => _state == GameClockState.paused;
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _records.length;

  Duration remaining(PieceColor color) {
    return color == PieceColor.white ? _whiteRemaining : _blackRemaining;
  }

  GameClockSnapshot get snapshot {
    return GameClockSnapshot(
      whiteRemaining: _whiteRemaining,
      blackRemaining: _blackRemaining,
      activeColor: _activeColor,
      state: _state,
      expiredColor: _expiredColor,
    );
  }

  void start({PieceColor activeColor = PieceColor.white}) {
    if (!enabled || _state != GameClockState.ready) {
      return;
    }
    _activeColor = activeColor;
    _expiredColor = null;
    _state = GameClockState.running;
    _lastReading = timeSource.elapsed;
    _turnStart = snapshot;
  }

  PieceColor? synchronize() {
    if (!isRunning) {
      return _expiredColor;
    }
    final Duration now = timeSource.elapsed;
    final Duration delta = now - _lastReading;
    _lastReading = now;
    if (delta <= Duration.zero) {
      return _expiredColor;
    }
    final PieceColor active = _activeColor!;
    final Duration updated = remaining(active) - delta;
    _setRemaining(active, _clamp(updated));
    if (updated <= Duration.zero) {
      _expiredColor = active;
      _state = GameClockState.finished;
    }
    return _expiredColor;
  }

  bool completeTurn({
    required String moveToken,
    required PieceColor movedColor,
  }) {
    synchronize();
    if (_state == GameClockState.finished || _activeColor != movedColor) {
      return false;
    }

    final GameClockSnapshot before = _turnStart ?? snapshot;
    _setRemaining(movedColor, remaining(movedColor) + increment);
    _activeColor = movedColor.opposite;
    _lastReading = timeSource.elapsed;
    final GameClockSnapshot after = snapshot;

    if (_cursor < _records.length) {
      _records.removeRange(_cursor, _records.length);
    }
    _records.add(
      _ClockTurnRecord(moveToken: moveToken, before: before, after: after),
    );
    _cursor++;
    _turnStart = after;
    return true;
  }

  bool canRedoMove(String moveToken) {
    return canRedo && _records[_cursor].moveToken == moveToken;
  }

  bool undo() {
    if (!canUndo) {
      return false;
    }
    _cursor--;
    _restore(_records[_cursor].before);
    _turnStart = snapshot;
    return true;
  }

  bool redo() {
    if (!canRedo) {
      return false;
    }
    _restore(_records[_cursor].after);
    _cursor++;
    _turnStart = snapshot;
    return true;
  }

  void pause() {
    synchronize();
    if (_state == GameClockState.running) {
      _state = GameClockState.paused;
    }
  }

  void resume() {
    if (_state != GameClockState.paused) {
      return;
    }
    _state = GameClockState.running;
    _lastReading = timeSource.elapsed;
  }

  void stop() {
    synchronize();
    if (_state != GameClockState.ready) {
      _state = GameClockState.finished;
    }
  }

  void restart({PieceColor activeColor = PieceColor.white}) {
    _whiteRemaining = initialTime;
    _blackRemaining = initialTime;
    _activeColor = null;
    _expiredColor = null;
    _state = GameClockState.ready;
    _lastReading = timeSource.elapsed;
    _records.clear();
    _cursor = 0;
    _turnStart = null;
    start(activeColor: activeColor);
  }

  void _restore(GameClockSnapshot value) {
    _whiteRemaining = value.whiteRemaining;
    _blackRemaining = value.blackRemaining;
    _activeColor = value.activeColor;
    _expiredColor = value.expiredColor;
    _state = value.state;
    _lastReading = timeSource.elapsed;
  }

  void _setRemaining(PieceColor color, Duration value) {
    if (color == PieceColor.white) {
      _whiteRemaining = value;
    } else {
      _blackRemaining = value;
    }
  }

  Duration _clamp(Duration value) {
    return value.isNegative ? Duration.zero : value;
  }
}

final class _ClockTurnRecord {
  const _ClockTurnRecord({
    required this.moveToken,
    required this.before,
    required this.after,
  });

  final String moveToken;
  final GameClockSnapshot before;
  final GameClockSnapshot after;
}
