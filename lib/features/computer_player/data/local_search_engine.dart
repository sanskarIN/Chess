import 'dart:async';
import 'dart:isolate';

import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../domain/chess_engine.dart';
import '../domain/engine_analysis.dart';
import '../domain/engine_configuration.dart';
import '../domain/engine_difficulty.dart';
import '../domain/engine_failure.dart';
import '../domain/engine_health_status.dart';
import '../domain/engine_move.dart';
import 'local_search.dart';

final class LocalSearchEngine implements ChessEngine {
  LocalSearchEngine({required EngineConfiguration initialConfiguration})
    : _configuration = initialConfiguration,
      _health = const EngineHealthStatus.stopped(
        engineName: 'Chess-Master Local Search',
      );

  final StreamController<EngineAnalysis> _analysisController =
      StreamController<EngineAnalysis>.broadcast();
  EngineConfiguration _configuration;
  EngineHealthStatus _health;
  Position? _position;
  Isolate? _searchIsolate;
  ReceivePort? _searchPort;
  Completer<_SearchResponse>? _searchCompleter;
  bool _disposed = false;

  @override
  Stream<EngineAnalysis> get analysis => _analysisController.stream;

  @override
  EngineConfiguration get configuration => _configuration;

  @override
  EngineHealthStatus get health => _health;

  @override
  Future<void> start() async {
    _ensureNotDisposed();
    if (_health.state == EngineLifecycleState.ready) {
      return;
    }
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.starting,
      engineName: 'Chess-Master Local Search',
    );
    await Future<void>.delayed(Duration.zero);
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.ready,
      engineName: 'Chess-Master Local Search',
    );
  }

  @override
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    await cancelSearch();
    _position = null;
    _health = const EngineHealthStatus.stopped(
      engineName: 'Chess-Master Local Search',
    );
  }

  @override
  Future<void> restart() async {
    _ensureNotDisposed();
    await stop();
    await start();
  }

  @override
  Future<void> newGame() async {
    _ensureReady();
    await cancelSearch();
    _position = null;
  }

  @override
  Future<void> configure(EngineConfiguration configuration) async {
    _ensureNotDisposed();
    if (_searchIsolate != null) {
      throw const EngineFailure(
        code: EngineFailureCode.alreadySearching,
        message: 'Configuration cannot change during an active search.',
      );
    }
    _configuration = configuration;
  }

  @override
  Future<void> setPosition(Position position) async {
    _ensureReady();
    if (_searchIsolate != null) {
      await cancelSearch();
    }
    _position = position;
  }

  @override
  Future<EngineMove> requestBestMove() async {
    final _SearchResponse response = await _search();
    return EngineMove(
      move: Move.fromUci(response.bestMoveUci),
      source: EngineMoveSource.localSearch,
      analysis: response.analysis,
    );
  }

  @override
  Future<EngineAnalysis> requestAnalysis() async {
    final _SearchResponse response = await _search();
    return response.analysis;
  }

  Future<_SearchResponse> _search() async {
    _ensureReady();
    final Position? position = _position;
    if (position == null) {
      throw const EngineFailure(
        code: EngineFailureCode.noPosition,
        message: 'Set a chess position before requesting a search.',
      );
    }
    if (_searchIsolate != null) {
      throw const EngineFailure(
        code: EngineFailureCode.alreadySearching,
        message: 'Only one engine search may run at a time.',
      );
    }

    final ReceivePort port = ReceivePort();
    final Completer<_SearchResponse> completer = Completer<_SearchResponse>();
    _searchPort = port;
    _searchCompleter = completer;
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.searching,
      engineName: 'Chess-Master Local Search',
    );

    port.listen((Object? message) {
      if (completer.isCompleted) {
        return;
      }
      if (message is Map<Object?, Object?> && message['error'] is String) {
        completer.completeError(
          EngineFailure(
            code: EngineFailureCode.invalidOutput,
            message: 'The local search worker returned an invalid result.',
            technicalDetails: message['error']! as String,
          ),
        );
        return;
      }
      try {
        final _SearchResponse response = _SearchResponse.fromMessage(message);
        completer.complete(response);
      } on Object catch (error, stackTrace) {
        completer.completeError(
          EngineFailure(
            code: EngineFailureCode.invalidOutput,
            message: 'The local search worker returned an invalid result.',
            technicalDetails: error.toString(),
          ),
          stackTrace,
        );
      }
    });

    _searchIsolate = await Isolate.spawn<List<Object?>>(
      _localSearchWorker,
      <Object?>[
        port.sendPort,
        FenCodec.encode(position),
        _configuration.searchDepth,
        _configuration.moveTime.inMilliseconds,
        _configuration.difficulty.index,
      ],
      errorsAreFatal: true,
      onError: port.sendPort,
    );

    try {
      final _SearchResponse response = await completer.future.timeout(
        _configuration.moveTime + const Duration(seconds: 2),
        onTimeout: () {
          throw const EngineFailure(
            code: EngineFailureCode.timeout,
            message: 'The local engine search timed out.',
          );
        },
      );
      _analysisController.add(response.analysis);
      _health = const EngineHealthStatus(
        state: EngineLifecycleState.ready,
        engineName: 'Chess-Master Local Search',
      );
      return response;
    } on EngineFailure catch (failure) {
      _health = EngineHealthStatus(
        state: switch (failure.code) {
          EngineFailureCode.timeout => EngineLifecycleState.degraded,
          EngineFailureCode.cancelled => EngineLifecycleState.ready,
          _ => EngineLifecycleState.crashed,
        },
        engineName: 'Chess-Master Local Search',
        detailCode: failure.code.name,
      );
      rethrow;
    } finally {
      _finishSearch();
    }
  }

  @override
  Future<void> cancelSearch() async {
    final Completer<_SearchResponse>? completer = _searchCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const EngineFailure(
          code: EngineFailureCode.cancelled,
          message: 'The active engine search was cancelled.',
        ),
      );
    }
    _finishSearch();
    if (!_disposed &&
        _health.state != EngineLifecycleState.stopped &&
        _health.state != EngineLifecycleState.disposed) {
      _health = const EngineHealthStatus(
        state: EngineLifecycleState.ready,
        engineName: 'Chess-Master Local Search',
      );
    }
  }

  void _finishSearch() {
    _searchIsolate?.kill(priority: Isolate.immediate);
    _searchIsolate = null;
    _searchPort?.close();
    _searchPort = null;
    _searchCompleter = null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await cancelSearch();
    _disposed = true;
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.disposed,
      engineName: 'Chess-Master Local Search',
    );
    await _analysisController.close();
  }

  void _ensureReady() {
    _ensureNotDisposed();
    if (_health.state != EngineLifecycleState.ready) {
      throw const EngineFailure(
        code: EngineFailureCode.notStarted,
        message: 'Start the engine before using it.',
      );
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const EngineFailure(
        code: EngineFailureCode.disposed,
        message: 'The engine has already been disposed.',
      );
    }
  }
}

final class _SearchResponse {
  const _SearchResponse({required this.bestMoveUci, required this.analysis});

  factory _SearchResponse.fromMessage(Object? message) {
    if (message is! Map<Object?, Object?>) {
      throw const FormatException('Search response must be a map.');
    }
    final Object? move = message['bestMove'];
    final Object? depth = message['depth'];
    final Object? nodes = message['nodes'];
    final Object? elapsedMillis = message['elapsedMillis'];
    final Object? score = message['score'];
    final Object? pv = message['pv'];
    if (move is! String ||
        depth is! int ||
        nodes is! int ||
        elapsedMillis is! int ||
        score is! int ||
        pv is! List<Object?>) {
      throw const FormatException('Search response fields are invalid.');
    }
    return _SearchResponse(
      bestMoveUci: move,
      analysis: EngineAnalysis(
        depth: depth,
        nodes: nodes,
        elapsed: Duration(milliseconds: elapsedMillis),
        scoreCentipawns: score,
        principalVariation: pv
            .whereType<String>()
            .map(Move.fromUci)
            .toList(growable: false),
      ),
    );
  }

  final String bestMoveUci;
  final EngineAnalysis analysis;
}

void _localSearchWorker(List<Object?> request) {
  final SendPort sendPort = request[0]! as SendPort;
  try {
    final String fen = request[1]! as String;
    final int depth = request[2]! as int;
    final int budgetMillis = request[3]! as int;
    final int difficultyIndex = request[4]! as int;
    final Map<String, Object?> response = searchPosition(
      fen: fen,
      maximumDepth: depth,
      budget: Duration(milliseconds: budgetMillis),
      difficulty: EngineDifficulty.values[difficultyIndex],
    );
    sendPort.send(response);
  } on Object catch (error) {
    sendPort.send(<String, Object?>{'error': error.toString()});
  }
}
