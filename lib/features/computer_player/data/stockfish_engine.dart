import 'dart:async';

import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../domain/chess_engine.dart';
import '../domain/engine_analysis.dart';
import '../domain/engine_configuration.dart';
import '../domain/engine_failure.dart';
import '../domain/engine_health_status.dart';
import '../domain/engine_move.dart';
import '../domain/engine_process.dart';
import 'stockfish_binary_resolver.dart';
import 'uci/uci_message.dart';
import 'uci/uci_message_parser.dart';

final class StockfishEngine implements ChessEngine {
  StockfishEngine({
    required EngineConfiguration initialConfiguration,
    required EngineProcess engineProcess,
    required StockfishBinaryResolver resolver,
    UciMessageParser messageParser = const UciMessageParser(),
  }) : _configuration = initialConfiguration,
       _process = engineProcess,
       _binaryResolver = resolver,
       _parser = messageParser,
       _health = const EngineHealthStatus.stopped(engineName: 'Stockfish');

  final EngineProcess _process;
  final StockfishBinaryResolver _binaryResolver;
  final UciMessageParser _parser;
  final StreamController<EngineAnalysis> _analysisController =
      StreamController<EngineAnalysis>.broadcast();
  EngineConfiguration _configuration;
  EngineHealthStatus _health;
  Position? _position;
  bool _disposed = false;
  bool _searching = false;
  Completer<void>? _cancelCompleter;

  @override
  Stream<EngineAnalysis> get analysis => _analysisController.stream;

  @override
  EngineConfiguration get configuration => _configuration;

  @override
  EngineHealthStatus get health => _health;

  @override
  Future<void> start() async {
    _ensureNotDisposed();
    if (_process.isRunning && _health.state == EngineLifecycleState.ready) {
      return;
    }
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.starting,
      engineName: 'Stockfish',
    );
    try {
      final StockfishBinary binary = await _binaryResolver.resolve();
      await _process.start(executablePath: binary.path);
      await _sendAndWait(
        'uci',
        (UciMessage message) => message is UciInitialized,
        const Duration(seconds: 5),
      );
      await _applyConfiguration();
      await _waitUntilReady();
      _health = EngineHealthStatus(
        state: EngineLifecycleState.ready,
        engineName: binary.distributionVerified
            ? 'Stockfish ${binary.sourceVersion}'
            : 'Stockfish development binary',
        detailCode: binary.distributionVerified ? binary.abi : 'unverified_dev',
      );
      unawaited(
        _process.exitCode.then((int code) {
          if (!_disposed && _health.state != EngineLifecycleState.stopped) {
            _health = EngineHealthStatus(
              state: EngineLifecycleState.crashed,
              engineName: 'Stockfish',
              detailCode: 'exit_$code',
            );
          }
        }),
      );
    } on EngineFailure {
      _health = const EngineHealthStatus(
        state: EngineLifecycleState.unsupported,
        engineName: 'Stockfish',
        detailCode: 'binary_unavailable',
      );
      rethrow;
    } on Object catch (error) {
      _health = EngineHealthStatus(
        state: EngineLifecycleState.crashed,
        engineName: 'Stockfish',
        detailCode: error.runtimeType.toString(),
      );
      throw EngineFailure(
        code: EngineFailureCode.crashed,
        message: 'Stockfish could not be started.',
        technicalDetails: error.toString(),
      );
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    await cancelSearch();
    await _process.stop();
    _position = null;
    _health = const EngineHealthStatus.stopped(engineName: 'Stockfish');
  }

  @override
  Future<void> restart() async {
    _ensureNotDisposed();
    await _process.stop(force: true);
    _searching = false;
    await start();
  }

  @override
  Future<void> newGame() async {
    _ensureReady();
    await cancelSearch();
    _process.writeLine('ucinewgame');
    await _waitUntilReady();
    _position = null;
  }

  @override
  Future<void> configure(EngineConfiguration configuration) async {
    _ensureNotDisposed();
    if (_searching) {
      throw const EngineFailure(
        code: EngineFailureCode.alreadySearching,
        message: 'Configuration cannot change during a search.',
      );
    }
    _configuration = configuration;
    if (_process.isRunning) {
      await _applyConfiguration();
      await _waitUntilReady();
    }
  }

  Future<void> _applyConfiguration() async {
    _process
      ..writeLine(
        'setoption name Skill Level value ${_configuration.skillLevel}',
      )
      ..writeLine('setoption name Hash value ${_configuration.hashMegabytes}')
      ..writeLine('setoption name Threads value ${_configuration.threads}');
  }

  @override
  Future<void> setPosition(Position position) async {
    _ensureReady();
    if (_searching) {
      await cancelSearch();
    }
    _position = position;
    _process.writeLine('position fen ${FenCodec.encode(position)}');
  }

  @override
  Future<EngineMove> requestBestMove() async {
    final _StockfishSearchResult result = await _search();
    return EngineMove(
      move: result.bestMove.move,
      ponder: result.bestMove.ponder,
      source: EngineMoveSource.stockfish,
      analysis: result.analysis,
    );
  }

  @override
  Future<EngineAnalysis> requestAnalysis() async {
    return (await _search()).analysis;
  }

  Future<_StockfishSearchResult> _search() async {
    _ensureReady();
    if (_position == null) {
      throw const EngineFailure(
        code: EngineFailureCode.noPosition,
        message: 'Set a chess position before requesting a search.',
      );
    }
    if (_searching) {
      throw const EngineFailure(
        code: EngineFailureCode.alreadySearching,
        message: 'Only one Stockfish search may run at a time.',
      );
    }
    _searching = true;
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.searching,
      engineName: 'Stockfish',
    );
    final Completer<_StockfishSearchResult> completer =
        Completer<_StockfishSearchResult>();
    final Completer<void> cancelCompleter = Completer<void>();
    _cancelCompleter = cancelCompleter;
    EngineAnalysis latest = const EngineAnalysis(
      depth: 0,
      nodes: 0,
      elapsed: Duration.zero,
      principalVariation: <Move>[],
    );
    late final StreamSubscription<String> subscription;
    subscription = _process.outputLines.listen((String line) {
      if (completer.isCompleted) {
        return;
      }
      try {
        final UciMessage message = _parser.parse(line);
        if (message is UciInfo) {
          latest = EngineAnalysis(
            depth: message.depth,
            nodes: message.nodes,
            elapsed: Duration(milliseconds: message.elapsedMilliseconds),
            scoreCentipawns: message.scoreCentipawns,
            mateIn: message.mateIn,
            principalVariation: message.principalVariation,
          );
          _analysisController.add(latest);
        } else if (message is UciBestMove) {
          completer.complete(
            _StockfishSearchResult(bestMove: message, analysis: latest),
          );
        }
      } on Object catch (error) {
        completer.completeError(
          EngineFailure(
            code: EngineFailureCode.invalidOutput,
            message: 'Stockfish returned invalid UCI output.',
            technicalDetails: '$line\n$error',
          ),
        );
      }
    });

    _process.writeLine(
      'go depth ${_configuration.searchDepth} '
      'movetime ${_configuration.moveTime.inMilliseconds}',
    );

    try {
      final _StockfishSearchResult result =
          await Future.any(<Future<_StockfishSearchResult>>[
            completer.future,
            cancelCompleter.future.then<_StockfishSearchResult>((_) {
              throw const EngineFailure(
                code: EngineFailureCode.cancelled,
                message: 'The Stockfish search was cancelled.',
              );
            }),
          ]).timeout(
            _configuration.moveTime + const Duration(seconds: 3),
            onTimeout: () {
              _process.writeLine('stop');
              throw const EngineFailure(
                code: EngineFailureCode.timeout,
                message: 'Stockfish did not answer before the engine timeout.',
              );
            },
          );
      _health = const EngineHealthStatus(
        state: EngineLifecycleState.ready,
        engineName: 'Stockfish',
      );
      return result;
    } on EngineFailure catch (failure) {
      _health = EngineHealthStatus(
        state: failure.code == EngineFailureCode.timeout
            ? EngineLifecycleState.degraded
            : EngineLifecycleState.ready,
        engineName: 'Stockfish',
        detailCode: failure.code.name,
      );
      rethrow;
    } finally {
      _searching = false;
      _cancelCompleter = null;
      await subscription.cancel();
    }
  }

  @override
  Future<void> cancelSearch() async {
    if (!_searching) {
      return;
    }
    _process.writeLine('stop');
    final Completer<void>? completer = _cancelCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _waitUntilReady() async {
    await _sendAndWait(
      'isready',
      (UciMessage message) => message is UciReady,
      const Duration(seconds: 5),
    );
  }

  Future<void> _sendAndWait(
    String command,
    bool Function(UciMessage message) predicate,
    Duration timeout,
  ) async {
    final Completer<void> completer = Completer<void>();
    late final StreamSubscription<String> subscription;
    subscription = _process.outputLines.listen((String line) {
      if (completer.isCompleted) {
        return;
      }
      try {
        if (predicate(_parser.parse(line))) {
          completer.complete();
        }
      } on FormatException {
        return;
      }
    });
    _process.writeLine(command);
    try {
      await completer.future.timeout(timeout);
    } on TimeoutException catch (error) {
      throw EngineFailure(
        code: EngineFailureCode.timeout,
        message: 'Stockfish did not complete the UCI handshake.',
        technicalDetails: error.toString(),
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stop();
    _disposed = true;
    _health = const EngineHealthStatus(
      state: EngineLifecycleState.disposed,
      engineName: 'Stockfish',
    );
    await _analysisController.close();
  }

  void _ensureReady() {
    _ensureNotDisposed();
    if (!_process.isRunning || _health.state != EngineLifecycleState.ready) {
      throw const EngineFailure(
        code: EngineFailureCode.notStarted,
        message: 'Start Stockfish before using it.',
      );
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const EngineFailure(
        code: EngineFailureCode.disposed,
        message: 'The Stockfish adapter has already been disposed.',
      );
    }
  }
}

final class _StockfishSearchResult {
  const _StockfishSearchResult({
    required this.bestMove,
    required this.analysis,
  });

  final UciBestMove bestMove;
  final EngineAnalysis analysis;
}
