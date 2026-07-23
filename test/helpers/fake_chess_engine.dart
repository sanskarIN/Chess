import 'dart:async';

import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/position.dart';
import 'package:chess_master/features/computer_player/domain/chess_engine.dart';
import 'package:chess_master/features/computer_player/domain/engine_analysis.dart';
import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_health_status.dart';
import 'package:chess_master/features/computer_player/domain/engine_move.dart';

final class FakeChessEngine implements ChessEngine {
  FakeChessEngine({
    required EngineConfiguration initialConfiguration,
    required Move Function(Position position) selector,
    this.searchGate,
  }) : _configuration = initialConfiguration,
       _moveSelector = selector;

  final Move Function(Position position) _moveSelector;
  final Completer<void>? searchGate;
  final StreamController<EngineAnalysis> _analysisController =
      StreamController<EngineAnalysis>.broadcast();
  EngineConfiguration _configuration;
  EngineHealthStatus _health = const EngineHealthStatus.stopped(
    engineName: 'Fake engine',
  );
  Position? _position;
  bool _cancelled = false;

  @override
  Stream<EngineAnalysis> get analysis => _analysisController.stream;

  @override
  EngineConfiguration get configuration => _configuration;

  @override
  EngineHealthStatus get health => _health;

  @override
  Future<void> cancelSearch() async {
    _cancelled = true;
    final Completer<void>? gate = searchGate;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
  }

  @override
  Future<void> configure(EngineConfiguration configuration) async {
    _configuration = configuration;
  }

  @override
  Future<void> dispose() async {
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.disposed,
      engineName: 'Fake engine',
    );
    await _analysisController.close();
  }

  @override
  Future<void> newGame() async {
    _position = null;
    _cancelled = false;
  }

  @override
  Future<EngineAnalysis> requestAnalysis() async {
    final EngineMove move = await requestBestMove();
    return move.analysis;
  }

  @override
  Future<EngineMove> requestBestMove() async {
    final Position position = _position!;
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.searching,
      engineName: 'Fake engine',
    );
    await searchGate?.future;
    if (_cancelled) {
      throw StateError('cancelled');
    }
    final EngineAnalysis analysis = EngineAnalysis(
      depth: 1,
      nodes: 20,
      elapsed: const Duration(milliseconds: 1),
      scoreCentipawns: 12,
      principalVariation: <Move>[_moveSelector(position)],
    );
    _analysisController.add(analysis);
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.ready,
      engineName: 'Fake engine',
    );
    return EngineMove(
      move: _moveSelector(position),
      source: EngineMoveSource.localSearch,
      analysis: analysis,
    );
  }

  @override
  Future<void> restart() async {
    await stop();
    await start();
  }

  @override
  Future<void> setPosition(Position position) async {
    _position = position;
  }

  @override
  Future<void> start() async {
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.ready,
      engineName: 'Fake engine',
    );
  }

  @override
  Future<void> stop() async {
    _health = const EngineHealthStatus.stopped(engineName: 'Fake engine');
  }
}
