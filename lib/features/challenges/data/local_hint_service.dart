import '../../chess/domain/model/position.dart';
import '../../computer_player/data/local_search_engine.dart';
import '../../computer_player/domain/engine_configuration.dart';
import '../../computer_player/domain/engine_difficulty.dart';
import '../domain/hint_suggestion.dart';

final class LocalHintService implements HintService {
  const LocalHintService();

  @override
  Future<HintSuggestion> generate(Position position) async {
    final LocalSearchEngine engine = LocalSearchEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.intermediate,
      ),
    );
    try {
      await engine.start();
      await engine.setPosition(position);
      final move = await engine.requestBestMove();
      return HintSuggestion(
        move: move.move,
        explanationKey: position.isCapture(move.move)
            ? 'hintExplanationCapture'
            : 'hintExplanationCandidate',
      );
    } finally {
      await engine.dispose();
    }
  }
}
