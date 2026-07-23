abstract interface class MonotonicTimeSource {
  Duration get elapsed;
}

final class StopwatchTimeSource implements MonotonicTimeSource {
  StopwatchTimeSource() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
