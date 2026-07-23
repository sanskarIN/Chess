import '../../chess/domain/model/position.dart';
import '../domain/training_puzzle.dart';
import '../domain/tutorial_lesson.dart';

final class TutorialLessonLaunch {
  const TutorialLessonLaunch({required this.lesson});

  final TutorialLesson lesson;
}

final class PuzzleListLaunch {
  const PuzzleListLaunch({this.type});

  final TrainingPuzzleType? type;
}

final class PuzzleLaunch {
  const PuzzleLaunch({required this.puzzle});

  final TrainingPuzzle puzzle;
}

final class PracticeBoardLaunch {
  const PracticeBoardLaunch({this.initialPosition});

  final Position? initialPosition;
}
