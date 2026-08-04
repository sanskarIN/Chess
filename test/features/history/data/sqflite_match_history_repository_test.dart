import 'package:chess_master/core/database/database_schema.dart';
import 'package:chess_master/core/database/transactional_database.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/history/data/sqflite_match_history_repository.dart';
import 'package:chess_master/features/history/domain/match_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqfliteMatchHistoryRepository repository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');
    for (final String statement in DatabaseSchema.creationStatements) {
      await database.execute(statement);
    }
    repository = SqfliteMatchHistoryRepository(
      database: _FfiTransactionDatabase(database),
    );
  });

  tearDown(() => database.close());

  test(
    'records completed matches idempotently and restores review data',
    () async {
      final ChessGame game = _blackCheckmateGame();
      final DateTime completedAt = DateTime.utc(2026, 7, 30, 12);
      final GameSetup setup = _computerSetup();

      expect(
        await repository.recordCompletedMatch(
          setup: setup,
          game: game,
          startedAt: completedAt.subtract(const Duration(seconds: 42)),
          completedAt: completedAt,
          hintCount: 0,
        ),
        isTrue,
      );
      expect(
        await repository.recordCompletedMatch(
          setup: setup,
          game: game,
          startedAt: completedAt.subtract(const Duration(seconds: 42)),
          completedAt: completedAt,
          hintCount: 0,
        ),
        isFalse,
      );

      final MatchHistoryEntry entry = (await repository.loadHistory()).single;
      expect(entry.outcome, MatchOutcome.win);
      expect(entry.opponentName, 'Computer');
      expect(entry.moveCount, 4);
      expect(entry.duration, const Duration(seconds: 42));
      expect(entry.game.moveRecords, hasLength(4));
      expect(entry.game.result, isNotNull);
      expect(
        await repository.loadHistory(filter: MatchHistoryFilter.losses),
        isEmpty,
      );
      expect(
        await repository.loadHistory(filter: MatchHistoryFilter.black),
        hasLength(1),
      );
    },
  );

  test(
    'derives statistics, preserves one-time achievements, and resets by time',
    () async {
      final DateTime completedAt = DateTime.utc(2026, 7, 30, 12);
      await repository.recordCompletedMatch(
        setup: _computerSetup(),
        game: _blackCheckmateGame(),
        startedAt: completedAt.subtract(const Duration(seconds: 30)),
        completedAt: completedAt,
        hintCount: 0,
      );

      final ChessStatistics before = await repository.loadStatistics(
        now: completedAt,
      );
      expect(before.gamesPlayed, 1);
      expect(before.wins, 1);
      expect(before.blackWins, 1);
      expect(before.totalMoves, 4);
      expect(before.fastestWin, const Duration(seconds: 30));
      expect(before.computerWinsByDifficulty[ComputerDifficulty.expert], 1);

      final Map<AchievementId, AchievementProgress> achievements = {
        for (final AchievementProgress value
            in await repository.loadAchievements(now: completedAt))
          value.id: value,
      };
      expect(achievements[AchievementId.firstMove]!.isUnlocked, isTrue);
      expect(achievements[AchievementId.firstWin]!.isUnlocked, isTrue);
      expect(achievements[AchievementId.firstCheckmate]!.isUnlocked, isTrue);
      expect(achievements[AchievementId.winAsBlack]!.isUnlocked, isTrue);
      expect(achievements[AchievementId.noHintVictory]!.isUnlocked, isTrue);
      final DateTime firstUnlocked =
          achievements[AchievementId.firstWin]!.unlockedAt!;

      await repository.resetStatistics(
        completedAt.add(const Duration(seconds: 1)),
      );
      final ChessStatistics after = await repository.loadStatistics(
        now: completedAt.add(const Duration(days: 1)),
      );
      expect(after.gamesPlayed, 0);
      expect(await repository.loadHistory(), hasLength(1));
      final AchievementProgress firstWin = (await repository.loadAchievements(
        now: completedAt.add(const Duration(days: 1)),
      )).firstWhere((value) => value.id == AchievementId.firstWin);
      expect(firstWin.isUnlocked, isTrue);
      expect(firstWin.unlockedAt, firstUnlocked);
    },
  );
}

ChessGame _blackCheckmateGame() {
  return ChessGame(gameId: 'history-checkmate')
    ..play(Move.fromUci('f2f3'))
    ..play(Move.fromUci('e7e5'))
    ..play(Move.fromUci('g2g4'))
    ..play(Move.fromUci('d8h4'));
}

GameSetup _computerSetup() {
  return GameSetup.computer(
    playerName: 'Alice',
    defaultPlayerName: 'Player',
    computerName: 'Computer',
    sideChoice: PlayerSideChoice.black,
    timeControl: TimeControl.threePlusTwo,
    difficulty: ComputerDifficulty.expert,
    hintsEnabled: true,
  );
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
