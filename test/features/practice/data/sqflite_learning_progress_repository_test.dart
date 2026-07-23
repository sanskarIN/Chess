import 'package:chess_master/core/database/database_schema.dart';
import 'package:chess_master/core/database/transactional_database.dart';
import 'package:chess_master/features/practice/data/sqflite_learning_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqfliteLearningProgressRepository repository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');
    for (final String statement in DatabaseSchema.creationStatements) {
      await database.execute(statement);
    }
    repository = SqfliteLearningProgressRepository(
      database: _FfiTransactionDatabase(database),
    );
  });

  tearDown(() => database.close());

  test('persists attempts, first completion, and first reward claim', () async {
    final DateTime first = DateTime.utc(2026, 7, 23, 10);
    final DateTime later = first.add(const Duration(hours: 1));
    await repository.recordTutorialAttempt('pawn-movement');
    await repository.completeTutorialLesson('pawn-movement', first);
    await repository.completeTutorialLesson('pawn-movement', later);
    await repository.markTutorialRewardClaimed('pawn-movement', first);
    await repository.markTutorialRewardClaimed('pawn-movement', later);

    final progress = (await repository
        .loadTutorialProgress())['pawn-movement']!;
    expect(progress.attempts, 1);
    expect(progress.completedAt, first);
    expect(progress.rewardClaimedAt, first);
  });

  test('keeps the lowest practice move count', () async {
    final DateTime now = DateTime.utc(2026, 7, 23);
    await repository.recordPracticeAttempt(
      exerciseId: 'puzzle-1',
      exerciseType: 'tactic',
      now: now,
    );
    await repository.completePracticeExercise(
      exerciseId: 'puzzle-1',
      exerciseType: 'tactic',
      moveCount: 5,
      now: now,
    );
    await repository.completePracticeExercise(
      exerciseId: 'puzzle-1',
      exerciseType: 'tactic',
      moveCount: 3,
      now: now.add(const Duration(minutes: 1)),
    );

    final progress = (await repository.loadPracticeProgress())['puzzle-1']!;
    expect(progress.attempts, 1);
    expect(progress.bestMoveCount, 3);
    expect(progress.isSolved, isTrue);
  });
}

final class _FfiTransactionDatabase implements TransactionalDatabase {
  const _FfiTransactionDatabase(this.database);

  final Database database;

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return database.transaction<T>(action);
  }
}
