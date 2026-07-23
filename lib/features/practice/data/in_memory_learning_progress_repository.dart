import '../domain/learning_progress.dart';

final class InMemoryLearningProgressRepository
    implements LearningProgressRepository {
  final Map<String, TutorialLessonProgress> _tutorial =
      <String, TutorialLessonProgress>{};
  final Map<String, PracticeExerciseProgress> _practice =
      <String, PracticeExerciseProgress>{};

  @override
  Future<Map<String, TutorialLessonProgress>> loadTutorialProgress() async {
    return Map<String, TutorialLessonProgress>.unmodifiable(_tutorial);
  }

  @override
  Future<TutorialLessonProgress> recordTutorialAttempt(String lessonId) async {
    final TutorialLessonProgress current =
        _tutorial[lessonId] ??
        TutorialLessonProgress(
          lessonId: lessonId,
          attempts: 0,
          completedAt: null,
          rewardClaimedAt: null,
        );
    final TutorialLessonProgress next = TutorialLessonProgress(
      lessonId: lessonId,
      attempts: current.attempts + 1,
      completedAt: current.completedAt,
      rewardClaimedAt: current.rewardClaimedAt,
    );
    _tutorial[lessonId] = next;
    return next;
  }

  @override
  Future<TutorialLessonProgress> completeTutorialLesson(
    String lessonId,
    DateTime now,
  ) async {
    final TutorialLessonProgress current =
        _tutorial[lessonId] ??
        TutorialLessonProgress(
          lessonId: lessonId,
          attempts: 0,
          completedAt: null,
          rewardClaimedAt: null,
        );
    final TutorialLessonProgress next = TutorialLessonProgress(
      lessonId: lessonId,
      attempts: current.attempts,
      completedAt: current.completedAt ?? now,
      rewardClaimedAt: current.rewardClaimedAt,
    );
    _tutorial[lessonId] = next;
    return next;
  }

  @override
  Future<void> markTutorialRewardClaimed(String lessonId, DateTime now) async {
    final TutorialLessonProgress current =
        _tutorial[lessonId] ??
        TutorialLessonProgress(
          lessonId: lessonId,
          attempts: 0,
          completedAt: now,
          rewardClaimedAt: null,
        );
    _tutorial[lessonId] = TutorialLessonProgress(
      lessonId: lessonId,
      attempts: current.attempts,
      completedAt: current.completedAt ?? now,
      rewardClaimedAt: current.rewardClaimedAt ?? now,
    );
  }

  @override
  Future<Map<String, PracticeExerciseProgress>> loadPracticeProgress() async {
    return Map<String, PracticeExerciseProgress>.unmodifiable(_practice);
  }

  @override
  Future<PracticeExerciseProgress> recordPracticeAttempt({
    required String exerciseId,
    required String exerciseType,
    required DateTime now,
  }) async {
    final PracticeExerciseProgress current =
        _practice[exerciseId] ??
        PracticeExerciseProgress(
          exerciseId: exerciseId,
          exerciseType: exerciseType,
          attempts: 0,
          solvedAt: null,
          bestMoveCount: null,
        );
    final PracticeExerciseProgress next = PracticeExerciseProgress(
      exerciseId: exerciseId,
      exerciseType: exerciseType,
      attempts: current.attempts + 1,
      solvedAt: current.solvedAt,
      bestMoveCount: current.bestMoveCount,
    );
    _practice[exerciseId] = next;
    return next;
  }

  @override
  Future<PracticeExerciseProgress> completePracticeExercise({
    required String exerciseId,
    required String exerciseType,
    required int moveCount,
    required DateTime now,
  }) async {
    if (moveCount <= 0) {
      throw ArgumentError.value(moveCount, 'moveCount', 'Must be positive.');
    }
    final PracticeExerciseProgress current =
        _practice[exerciseId] ??
        PracticeExerciseProgress(
          exerciseId: exerciseId,
          exerciseType: exerciseType,
          attempts: 0,
          solvedAt: null,
          bestMoveCount: null,
        );
    final int bestMoveCount = current.bestMoveCount == null
        ? moveCount
        : (moveCount < current.bestMoveCount!
              ? moveCount
              : current.bestMoveCount!);
    final PracticeExerciseProgress next = PracticeExerciseProgress(
      exerciseId: exerciseId,
      exerciseType: exerciseType,
      attempts: current.attempts,
      solvedAt: current.solvedAt ?? now,
      bestMoveCount: bestMoveCount,
    );
    _practice[exerciseId] = next;
    return next;
  }
}
