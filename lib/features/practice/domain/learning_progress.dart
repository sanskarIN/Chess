final class TutorialLessonProgress {
  const TutorialLessonProgress({
    required this.lessonId,
    required this.attempts,
    required this.completedAt,
    required this.rewardClaimedAt,
  });

  final String lessonId;
  final int attempts;
  final DateTime? completedAt;
  final DateTime? rewardClaimedAt;

  bool get isCompleted => completedAt != null;
}

final class PracticeExerciseProgress {
  const PracticeExerciseProgress({
    required this.exerciseId,
    required this.exerciseType,
    required this.attempts,
    required this.solvedAt,
    required this.bestMoveCount,
  });

  final String exerciseId;
  final String exerciseType;
  final int attempts;
  final DateTime? solvedAt;
  final int? bestMoveCount;

  bool get isSolved => solvedAt != null;
}

abstract interface class LearningProgressRepository {
  Future<Map<String, TutorialLessonProgress>> loadTutorialProgress();

  Future<TutorialLessonProgress> recordTutorialAttempt(String lessonId);

  Future<TutorialLessonProgress> completeTutorialLesson(
    String lessonId,
    DateTime now,
  );

  Future<void> markTutorialRewardClaimed(String lessonId, DateTime now);

  Future<Map<String, PracticeExerciseProgress>> loadPracticeProgress();

  Future<PracticeExerciseProgress> recordPracticeAttempt({
    required String exerciseId,
    required String exerciseType,
    required DateTime now,
  });

  Future<PracticeExerciseProgress> completePracticeExercise({
    required String exerciseId,
    required String exerciseType,
    required int moveCount,
    required DateTime now,
  });
}
