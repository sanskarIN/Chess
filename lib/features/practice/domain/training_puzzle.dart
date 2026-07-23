import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';

enum TrainingPuzzleType { mateInOne, mateInTwo, tactic, opening, endgame }

enum TrainingDifficulty { beginner, intermediate, advanced }

final class TrainingPuzzle {
  const TrainingPuzzle({
    required this.id,
    required this.type,
    required this.titleLocalizationKey,
    required this.descriptionLocalizationKey,
    required this.initialPosition,
    required this.solution,
    required this.difficulty,
    required this.source,
    required this.license,
  });

  final String id;
  final TrainingPuzzleType type;
  final String titleLocalizationKey;
  final String descriptionLocalizationKey;
  final Position initialPosition;
  final List<Move> solution;
  final TrainingDifficulty difficulty;
  final String source;
  final String license;
}

abstract interface class TrainingPuzzleRepository {
  Future<List<TrainingPuzzle>> load();
}
