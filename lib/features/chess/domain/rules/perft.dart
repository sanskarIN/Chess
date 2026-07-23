import '../model/position.dart';
import 'move_generator.dart';

final class Perft {
  const Perft({this.generator = const MoveGenerator()});

  final MoveGenerator generator;

  int count(Position position, int depth) {
    if (depth < 0) {
      throw ArgumentError.value(depth, 'depth', 'Must not be negative.');
    }
    if (depth == 0) {
      return 1;
    }
    int nodes = 0;
    for (final move in generator.legalMoves(position)) {
      nodes += count(position.applyUnchecked(move), depth - 1);
    }
    return nodes;
  }
}
