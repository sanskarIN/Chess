import '../../chess/domain/model/move.dart';
import 'engine_analysis.dart';

enum EngineMoveSource { stockfish, localSearch }

final class EngineMove {
  const EngineMove({
    required this.move,
    required this.source,
    required this.analysis,
    this.ponder,
  });

  final Move move;
  final Move? ponder;
  final EngineMoveSource source;
  final EngineAnalysis analysis;
}
