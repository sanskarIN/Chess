import '../../chess/domain/model/move.dart';

final class EngineAnalysis {
  const EngineAnalysis({
    required this.depth,
    required this.nodes,
    required this.elapsed,
    required this.principalVariation,
    this.scoreCentipawns,
    this.mateIn,
  });

  final int depth;
  final int nodes;
  final Duration elapsed;
  final int? scoreCentipawns;
  final int? mateIn;
  final List<Move> principalVariation;
}
