import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/engine_process.dart';

final class IoEngineProcess implements EngineProcess {
  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  Process? _process;
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _errorSubscription;
  Future<int>? _exitCode;

  @override
  Stream<String> get errorLines => _errorController.stream;

  @override
  Future<int> get exitCode => _exitCode ?? Future<int>.value(-1);

  @override
  bool get isRunning => _process != null;

  @override
  Stream<String> get outputLines => _outputController.stream;

  @override
  Future<void> start({
    required String executablePath,
    List<String> arguments = const <String>[],
  }) async {
    if (_process != null) {
      throw StateError('The engine process is already running.');
    }
    final Process process = await Process.start(
      executablePath,
      arguments,
      runInShell: false,
    );
    _process = process;
    _exitCode = process.exitCode.whenComplete(() {
      _process = null;
    });
    _outputSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_outputController.add);
    _errorSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_errorController.add);
  }

  @override
  void writeLine(String line) {
    final Process? process = _process;
    if (process == null) {
      throw StateError('The engine process is not running.');
    }
    process.stdin.writeln(line);
  }

  @override
  Future<void> stop({bool force = false}) async {
    final Process? process = _process;
    if (process == null) {
      return;
    }
    if (!force) {
      process.stdin.writeln('quit');
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        process.kill();
      }
    } else {
      process.kill();
    }
    await _outputSubscription?.cancel();
    await _errorSubscription?.cancel();
    _outputSubscription = null;
    _errorSubscription = null;
    _process = null;
  }
}
