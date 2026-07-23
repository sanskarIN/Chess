import '../../chess/domain/model/position.dart';
import '../domain/chess_engine.dart';
import '../domain/engine_analysis.dart';
import '../domain/engine_configuration.dart';
import '../domain/engine_health_status.dart';
import '../domain/engine_move.dart';

final class EngineService {
  EngineService({required ChessEngine ownedEngine}) : _engine = ownedEngine;

  final ChessEngine _engine;
  Future<void> _serial = Future<void>.value();
  bool _disposed = false;

  EngineHealthStatus get health => _engine.health;
  Stream<EngineAnalysis> get analysis => _engine.analysis;

  Future<void> start() => _enqueue(_engine.start);

  Future<void> stop() => _enqueue(_engine.stop);

  Future<void> restart() => _enqueue(_engine.restart);

  Future<void> newGame() => _enqueue(_engine.newGame);

  Future<void> configure(EngineConfiguration configuration) {
    return _enqueue(() => _engine.configure(configuration));
  }

  Future<void> setPosition(Position position) {
    return _enqueue(() => _engine.setPosition(position));
  }

  Future<EngineMove> requestBestMove() {
    return _enqueueValue(_engine.requestBestMove);
  }

  Future<EngineAnalysis> requestAnalysis() {
    return _enqueueValue(_engine.requestAnalysis);
  }

  Future<void> cancelSearch() => _engine.cancelSearch();

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _serial;
    await _engine.dispose();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    if (_disposed) {
      throw StateError('The engine service has been disposed.');
    }
    final Future<void> next = _serial.then((_) => operation());
    _serial = next.catchError((Object _) {});
    return next;
  }

  Future<T> _enqueueValue<T>(Future<T> Function() operation) {
    if (_disposed) {
      throw StateError('The engine service has been disposed.');
    }
    final Future<T> next = _serial.then((_) => operation());
    _serial = next.then<void>((_) {}).catchError((Object _) {});
    return next;
  }
}
