import 'dart:convert';

import 'package:chess_master/core/database/database_schema.dart';
import 'package:chess_master/core/database/transactional_database.dart';
import 'package:chess_master/features/settings/data/local_data_service.dart';
import 'package:chess_master/features/settings/domain/data_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late LocalDataService service;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await database.execute('PRAGMA foreign_keys = ON');
    await database.transaction((Transaction transaction) async {
      for (final String statement in DatabaseSchema.creationStatements) {
        await transaction.execute(statement);
      }
      await _seedEveryExportedTable(transaction);
    });
    service = LocalDataService(_FfiTransactionDatabase(database));
  });

  tearDown(() => database.close());

  test(
    'exports, previews, replaces, and restores every supported table',
    () async {
      final String snapshot = await service.exportSnapshot();
      final DataSnapshotPreview preview = service.preview(snapshot);

      expect(preview.formatVersion, LocalDataService.snapshotVersion);
      expect(preview.tableCounts, hasLength(17));
      expect(preview.tableCounts.values, everyElement(greaterThanOrEqualTo(1)));

      await service.deleteAllLocalData();
      final StorageDiagnostic empty = await service.diagnostics();
      expect(empty.tableCounts.values, everyElement(0));

      await service.importSnapshot(snapshot, mode: DataImportMode.replace);
      final StorageDiagnostic restored = await service.diagnostics();
      expect(restored.integrityResult, 'ok');
      expect(restored.tableCounts, preview.tableCounts);
      expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test('merge is idempotent and preserves existing primary-key rows', () async {
    final String snapshot = await service.exportSnapshot();
    await service.importSnapshot(snapshot, mode: DataImportMode.merge);

    final StorageDiagnostic diagnostic = await service.diagnostics();

    expect(diagnostic.tableCounts['games'], 1);
    expect(diagnostic.tableCounts['reward_transactions'], 1);
    expect(diagnostic.integrityResult, 'ok');
  });

  test(
    'targeted deletion operations affect only their documented data',
    () async {
      await service.deleteMatchHistory();
      await service.resetStatistics();
      await service.clearRecentOpponents();
      await service.resetChallenges();
      await service.resetRewards();

      StorageDiagnostic diagnostic = await service.diagnostics();
      expect(diagnostic.tableCounts['match_history'], 0);
      expect(diagnostic.tableCounts['statistics'], 0);
      expect(diagnostic.tableCounts['recent_opponents'], 0);
      expect(diagnostic.tableCounts['daily_challenges'], 0);
      expect(diagnostic.tableCounts['challenge_progress'], 0);
      expect(diagnostic.tableCounts['challenge_events'], 0);
      expect(diagnostic.tableCounts['wallet_balances'], 0);
      expect(diagnostic.tableCounts['reward_transactions'], 0);
      expect(diagnostic.tableCounts['saved_games'], 1);

      await service.deleteSavedGames();
      diagnostic = await service.diagnostics();
      expect(diagnostic.tableCounts['saved_games'], 0);
      expect(diagnostic.tableCounts['games'], 0);
      expect(diagnostic.tableCounts['moves'], 0);
    },
  );

  test('exports a privacy-safe reward ledger document', () async {
    final Map<String, Object?> ledger =
        jsonDecode(await service.exportRewardLedger()) as Map<String, Object?>;

    expect(ledger['formatVersion'], LocalDataService.snapshotVersion);
    expect(ledger['walletBalances'], isA<List<Object?>>());
    expect(ledger['rewardTransactions'], isA<List<Object?>>());
    expect(ledger, isNot(contains('player_profiles')));
    expect(ledger, isNot(contains('recent_opponents')));
  });

  test(
    'rejects malformed, incomplete, future, and unknown-table snapshots',
    () {
      expect(() => service.preview('{bad json'), throwsA(anything));
      expect(
        () => service.preview(
          '{"formatVersion":999,"schemaVersion":3,'
          '"createdAt":"2026-07-23T00:00:00Z","tables":{}}',
        ),
        throwsA(isA<DataManagementFailure>()),
      );
      expect(
        () => service.preview(
          '{"formatVersion":1,"schemaVersion":3,'
          '"createdAt":"2026-07-23T00:00:00Z",'
          '"tables":{"unknown":[]}}',
        ),
        throwsA(isA<DataManagementFailure>()),
      );
    },
  );

  test('reports unavailable storage explicitly', () {
    const LocalDataService unavailable = LocalDataService(null);

    expect(
      unavailable.exportSnapshot,
      throwsA(
        isA<DataManagementFailure>().having(
          (DataManagementFailure failure) => failure.code,
          'code',
          'database_unavailable',
        ),
      ),
    );
  });
}

Future<void> _seedEveryExportedTable(Transaction transaction) async {
  const int now = 1784808000000;
  await transaction.insert('app_settings', <String, Object?>{
    'setting_key': 'test-setting',
    'value_json': 'true',
    'value_type': 'bool',
    'updated_at': now,
  });
  await transaction.insert('player_profiles', <String, Object?>{
    'profile_id': 'profile-1',
    'display_name': 'Local player',
    'is_default': 1,
    'created_at': now,
    'updated_at': now,
  });
  await transaction.insert('games', <String, Object?>{
    'game_id': 'game-1',
    'mode': 'local',
    'status': 'completed',
    'initial_fen': 'startpos',
    'current_fen': 'after-e4',
    'white_name': 'White',
    'black_name': 'Black',
    'result': '1-0',
    'result_reason': 'checkmate',
    'started_at': now,
    'completed_at': now,
    'updated_at': now,
  });
  await transaction.insert('moves', <String, Object?>{
    'move_id': 'move-1',
    'game_id': 'game-1',
    'ply': 1,
    'from_square': 'e2',
    'to_square': 'e4',
    'san': 'e4',
    'fen_after': 'after-e4',
    'elapsed_millis': 100,
    'created_at': now,
  });
  await transaction.insert('saved_games', <String, Object?>{
    'saved_game_id': 'save-1',
    'game_id': 'game-1',
    'title': 'Test game',
    'created_at': now,
    'updated_at': now,
  });
  await transaction.insert('match_history', <String, Object?>{
    'history_id': 'history-1',
    'game_id': 'game-1',
    'opponent_type': 'local',
    'player_color': 'white',
    'result': 'win',
    'result_reason': 'checkmate',
    'duration_seconds': 30,
    'move_count': 1,
    'hint_count': 0,
    'completed_at': now,
  });
  await transaction.insert('statistics', <String, Object?>{
    'statistic_key': 'wins',
    'scope': 'all',
    'integer_value': 1,
    'updated_at': now,
  });
  await transaction.insert('daily_challenges', <String, Object?>{
    'challenge_id': 'challenge-1',
    'local_date': '2026-07-23',
    'challenge_type': 'finishMatch',
    'title_key': 'challengeFinishTitle',
    'description_key': 'challengeFinishDescription',
    'target_value': 1,
    'reward_type': 'coins',
    'reward_amount': 20,
    'difficulty': 'easy',
    'eligibility_json': '{}',
    'definition_version': 1,
    'coin_reward': 20,
    'hint_reward': 0,
  });
  await transaction.insert('challenge_progress', <String, Object?>{
    'challenge_id': 'challenge-1',
    'current_value': 1,
    'completed_at': now,
    'claimed_at': now,
    'updated_at': now,
  });
  await transaction.insert('wallet_balances', <String, Object?>{
    'asset_type': 'coin',
    'balance': 20,
    'updated_at': now,
  });
  await transaction.insert('reward_transactions', <String, Object?>{
    'transaction_id': 'reward-1',
    'ledger_sequence': 1,
    'transaction_type': 'challengeReward',
    'asset_type': 'coin',
    'amount': 20,
    'balance_before': 0,
    'balance_after': 20,
    'source': 'challenge:challenge-1',
    'timestamp': now,
    'related_challenge_id': 'challenge-1',
    'app_version': '0.9.0',
    'previous_integrity_hash': '',
    'integrity_hash': 'test-integrity-hash',
  });
  await transaction.insert('challenge_events', <String, Object?>{
    'event_id': 'event-1',
    'challenge_type': 'finishMatch',
    'amount': 1,
    'local_date': '2026-07-23',
    'recorded_at': now,
  });
  await transaction.insert('achievements', <String, Object?>{
    'achievement_id': 'achievement-1',
    'progress': 1,
    'target': 1,
    'unlocked_at': now,
    'reward_claimed_at': now,
    'definition_version': 1,
    'updated_at': now,
  });
  await transaction.insert('tutorial_progress', <String, Object?>{
    'lesson_id': 'lesson-1',
    'attempts': 1,
    'completed_at': now,
    'reward_claimed_at': now,
    'updated_at': now,
  });
  await transaction.insert('practice_progress', <String, Object?>{
    'exercise_id': 'exercise-1',
    'exercise_type': 'puzzle',
    'attempts': 1,
    'solved_at': now,
    'best_move_count': 1,
    'updated_at': now,
  });
  await transaction.insert('recent_opponents', <String, Object?>{
    'opponent_id': 'opponent-1',
    'display_name': 'Friend',
    'opponent_type': 'friend',
    'last_played_at': now,
  });
  await transaction.insert('developer_preferences', <String, Object?>{
    'preference_key': 'debug-overlay',
    'value_json': 'true',
    'updated_at': now,
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
