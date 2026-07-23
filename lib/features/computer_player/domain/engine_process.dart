abstract interface class EngineProcess {
  bool get isRunning;
  Stream<String> get outputLines;
  Stream<String> get errorLines;
  Future<int> get exitCode;

  Future<void> start({
    required String executablePath,
    List<String> arguments = const <String>[],
  });
  void writeLine(String line);
  Future<void> stop({bool force = false});
}
