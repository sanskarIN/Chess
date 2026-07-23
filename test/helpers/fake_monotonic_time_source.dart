import 'package:chess_master/features/local_multiplayer/domain/monotonic_time_source.dart';

final class FakeMonotonicTimeSource implements MonotonicTimeSource {
  Duration _elapsed = Duration.zero;

  @override
  Duration get elapsed => _elapsed;

  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'Must not be negative.');
    }
    _elapsed += duration;
  }
}
