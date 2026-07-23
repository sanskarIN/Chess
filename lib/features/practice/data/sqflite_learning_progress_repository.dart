import 'package:sqflite/sqflite.dart';

import '../../../core/database/transactional_database.dart';
import '../domain/learning_progress.dart';

final class SqfliteLearningProgressRepository
    implements LearningProgressRepository {
  const SqfliteLearningProgressRepository({required this.database});

  final TransactionalDatabase database;

  @override
  Future<Map<String, TutorialLessonProgress>> loadTutorialProgress() {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'tutorial_progress',
      );
      return Map<String, TutorialLessonProgress>.unmodifiable(
        <String, TutorialLessonProgress>{
          for (final Map<String, Object?> row in rows)
            row['lesson_id']! as String: _tutorialFromRow(row),
        },
      );
    });
  }

  @override
  Future<TutorialLessonProgress> recordTutorialAttempt(String lessonId) {
    return database.runTransaction((Transaction transaction) async {
      final int now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await transaction.rawInsert(
        '''
INSERT INTO tutorial_progress (
  lesson_id, attempts, completed_at, reward_claimed_at, updated_at
) VALUES (?, 1, NULL, NULL, ?)
ON CONFLICT(lesson_id) DO UPDATE SET
  attempts = attempts + 1,
  updated_at = excluded.updated_at
''',
        <Object?>[lessonId, now],
      );
      return _readTutorial(transaction, lessonId);
    });
  }

  @override
  Future<TutorialLessonProgress> completeTutorialLesson(
    String lessonId,
    DateTime now,
  ) {
    return database.runTransaction((Transaction transaction) async {
      final int timestamp = now.toUtc().millisecondsSinceEpoch;
      await transaction.rawInsert(
        '''
INSERT INTO tutorial_progress (
  lesson_id, attempts, completed_at, reward_claimed_at, updated_at
) VALUES (?, 0, ?, NULL, ?)
ON CONFLICT(lesson_id) DO UPDATE SET
  completed_at = COALESCE(completed_at, excluded.completed_at),
  updated_at = excluded.updated_at
''',
        <Object?>[lessonId, timestamp, timestamp],
      );
      return _readTutorial(transaction, lessonId);
    });
  }

  @override
  Future<void> markTutorialRewardClaimed(String lessonId, DateTime now) {
    return database.runTransaction((Transaction transaction) async {
      final int timestamp = now.toUtc().millisecondsSinceEpoch;
      await transaction.rawInsert(
        '''
INSERT INTO tutorial_progress (
  lesson_id, attempts, completed_at, reward_claimed_at, updated_at
) VALUES (?, 0, ?, ?, ?)
ON CONFLICT(lesson_id) DO UPDATE SET
  completed_at = COALESCE(completed_at, excluded.completed_at),
  reward_claimed_at = COALESCE(
    reward_claimed_at,
    excluded.reward_claimed_at
  ),
  updated_at = excluded.updated_at
''',
        <Object?>[lessonId, timestamp, timestamp, timestamp],
      );
    });
  }

  @override
  Future<Map<String, PracticeExerciseProgress>> loadPracticeProgress() {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'practice_progress',
      );
      return Map<String, PracticeExerciseProgress>.unmodifiable(
        <String, PracticeExerciseProgress>{
          for (final Map<String, Object?> row in rows)
            row['exercise_id']! as String: _practiceFromRow(row),
        },
      );
    });
  }

  @override
  Future<PracticeExerciseProgress> recordPracticeAttempt({
    required String exerciseId,
    required String exerciseType,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      final int timestamp = now.toUtc().millisecondsSinceEpoch;
      await transaction.rawInsert(
        '''
INSERT INTO practice_progress (
  exercise_id, exercise_type, attempts, solved_at, best_move_count, updated_at
) VALUES (?, ?, 1, NULL, NULL, ?)
ON CONFLICT(exercise_id) DO UPDATE SET
  attempts = attempts + 1,
  exercise_type = excluded.exercise_type,
  updated_at = excluded.updated_at
''',
        <Object?>[exerciseId, exerciseType, timestamp],
      );
      return _readPractice(transaction, exerciseId);
    });
  }

  @override
  Future<PracticeExerciseProgress> completePracticeExercise({
    required String exerciseId,
    required String exerciseType,
    required int moveCount,
    required DateTime now,
  }) {
    if (moveCount <= 0) {
      throw ArgumentError.value(moveCount, 'moveCount', 'Must be positive.');
    }
    return database.runTransaction((Transaction transaction) async {
      final int timestamp = now.toUtc().millisecondsSinceEpoch;
      await transaction.rawInsert(
        '''
INSERT INTO practice_progress (
  exercise_id, exercise_type, attempts, solved_at, best_move_count, updated_at
) VALUES (?, ?, 0, ?, ?, ?)
ON CONFLICT(exercise_id) DO UPDATE SET
  exercise_type = excluded.exercise_type,
  solved_at = COALESCE(solved_at, excluded.solved_at),
  best_move_count = CASE
    WHEN best_move_count IS NULL THEN excluded.best_move_count
    WHEN excluded.best_move_count < best_move_count
      THEN excluded.best_move_count
    ELSE best_move_count
  END,
  updated_at = excluded.updated_at
''',
        <Object?>[exerciseId, exerciseType, timestamp, moveCount, timestamp],
      );
      return _readPractice(transaction, exerciseId);
    });
  }

  Future<TutorialLessonProgress> _readTutorial(
    Transaction transaction,
    String lessonId,
  ) async {
    final List<Map<String, Object?>> rows = await transaction.query(
      'tutorial_progress',
      where: 'lesson_id = ?',
      whereArgs: <Object?>[lessonId],
      limit: 1,
    );
    return _tutorialFromRow(rows.single);
  }

  Future<PracticeExerciseProgress> _readPractice(
    Transaction transaction,
    String exerciseId,
  ) async {
    final List<Map<String, Object?>> rows = await transaction.query(
      'practice_progress',
      where: 'exercise_id = ?',
      whereArgs: <Object?>[exerciseId],
      limit: 1,
    );
    return _practiceFromRow(rows.single);
  }

  TutorialLessonProgress _tutorialFromRow(Map<String, Object?> row) {
    return TutorialLessonProgress(
      lessonId: row['lesson_id']! as String,
      attempts: row['attempts']! as int,
      completedAt: _dateTime(row['completed_at']),
      rewardClaimedAt: _dateTime(row['reward_claimed_at']),
    );
  }

  PracticeExerciseProgress _practiceFromRow(Map<String, Object?> row) {
    return PracticeExerciseProgress(
      exerciseId: row['exercise_id']! as String,
      exerciseType: row['exercise_type']! as String,
      attempts: row['attempts']! as int,
      solvedAt: _dateTime(row['solved_at']),
      bestMoveCount: row['best_move_count'] as int?,
    );
  }

  DateTime? _dateTime(Object? milliseconds) {
    return milliseconds is int
        ? DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true)
        : null;
  }
}
