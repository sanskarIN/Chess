import 'dart:async';

import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/computer_player/data/stockfish_binary_resolver.dart';
import 'package:chess_master/features/computer_player/data/stockfish_engine.dart';
import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_difficulty.dart';
import 'package:chess_master/features/computer_player/domain/engine_move.dart';
import 'package:chess_master/features/computer_player/domain/engine_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('performs UCI handshake, configuration, position, and search', () async {
    final _FakeEngineProcess process = _FakeEngineProcess();
    final StockfishEngine engine = StockfishEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.expert,
      ),
      engineProcess: process,
      resolver: const _FakeBinaryResolver(),
    );

    await engine.start();
    await engine.setPosition(FenCodec.decode(FenCodec.standardInitialPosition));
    final EngineMove move = await engine.requestBestMove();

    expect(move.move.uci, 'e2e4');
    expect(move.ponder?.uci, 'e7e5');
    expect(move.source, EngineMoveSource.stockfish);
    expect(move.analysis.depth, 8);
    expect(process.commands, contains('uci'));
    expect(process.commands, contains('isready'));
    expect(process.commands, contains('setoption name Skill Level value 12'));
    expect(
      process.commands.any((String line) => line.startsWith('position fen ')),
      isTrue,
    );
    expect(process.commands, contains('go depth 3 movetime 1400'));

    await engine.dispose();
  });
}

final class _FakeBinaryResolver implements StockfishBinaryResolver {
  const _FakeBinaryResolver();

  @override
  Future<StockfishBinary> resolve() async {
    return const StockfishBinary(
      path: 'fake-stockfish',
      abi: 'x86_64',
      sourceVersion: 'test',
      sha256: 'test-checksum',
      distributionVerified: true,
    );
  }
}

final class _FakeEngineProcess implements EngineProcess {
  final StreamController<String> _output = StreamController<String>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();
  final Completer<int> _exitCode = Completer<int>();
  final List<String> commands = <String>[];
  bool _running = false;

  @override
  Stream<String> get errorLines => _errors.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  bool get isRunning => _running;

  @override
  Stream<String> get outputLines => _output.stream;

  @override
  Future<void> start({
    required String executablePath,
    List<String> arguments = const <String>[],
  }) async {
    _running = true;
  }

  @override
  Future<void> stop({bool force = false}) async {
    _running = false;
    if (!_exitCode.isCompleted) {
      _exitCode.complete(0);
    }
    await _output.close();
    await _errors.close();
  }

  @override
  void writeLine(String line) {
    commands.add(line);
    if (line == 'uci') {
      scheduleMicrotask(() {
        _output
          ..add('id name Stockfish test')
          ..add('uciok');
      });
    } else if (line == 'isready') {
      scheduleMicrotask(() => _output.add('readyok'));
    } else if (line.startsWith('go ')) {
      scheduleMicrotask(() {
        _output
          ..add(
            'info depth 8 score cp 21 nodes 1000 time 15 '
            'pv e2e4 e7e5',
          )
          ..add('bestmove e2e4 ponder e7e5');
      });
    }
  }
}
