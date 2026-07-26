import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_schema.dart';
import '../../../core/database/transactional_database.dart';
import '../domain/data_snapshot.dart';

final class LocalDataService {
  const LocalDataService(this._database);

  static const int snapshotVersion = 1;
  static const List<String> _tables = <String>[
    'app_settings',
    'player_profiles',
    'games',
    'moves',
    'saved_games',
    'match_history',
    'statistics',
    'daily_challenges',
    'challenge_progress',
    'wallet_balances',
    'reward_transactions',
    'challenge_events',
    'achievements',
    'tutorial_progress',
    'practice_progress',
    'recent_opponents',
    'developer_preferences',
  ];

  final TransactionalDatabase? _database;

  Future<String> exportSnapshot() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      final Map<String, Object?> tables = <String, Object?>{};
      for (final String table in _tables) {
        tables[table] = await transaction.query(table);
      }
      return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'formatVersion': snapshotVersion,
        'schemaVersion': DatabaseSchema.currentVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'tables': tables,
      });
    });
  }

  DataSnapshotPreview preview(String source) {
    final Map<String, Object?> document = _parse(source);
    final Map<String, Object?> tables =
        document['tables']! as Map<String, Object?>;
    return DataSnapshotPreview(
      formatVersion: document['formatVersion']! as int,
      createdAt: DateTime.parse(document['createdAt']! as String).toUtc(),
      tableCounts: Map<String, int>.unmodifiable(<String, int>{
        for (final MapEntry<String, Object?> entry in tables.entries)
          entry.key: (entry.value! as List<Object?>).length,
      }),
    );
  }

  Future<void> importSnapshot(String source, {required DataImportMode mode}) {
    final Map<String, Object?> document = _parse(source);
    final Map<String, Object?> tables =
        document['tables']! as Map<String, Object?>;
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      if (mode == DataImportMode.replace) {
        for (final String table in _tables.reversed) {
          await transaction.delete(table);
        }
      }
      for (final String table in _tables) {
        final List<Object?> rows = tables[table]! as List<Object?>;
        for (final Object? rawRow in rows) {
          await transaction.insert(
            table,
            Map<String, Object?>.from(rawRow! as Map<String, Object?>),
            conflictAlgorithm: mode == DataImportMode.merge
                ? ConflictAlgorithm.ignore
                : ConflictAlgorithm.replace,
          );
        }
      }
      final List<Map<String, Object?>> check = await transaction.rawQuery(
        'PRAGMA foreign_key_check',
      );
      if (check.isNotEmpty) {
        throw const DataManagementFailure('foreign_key_check_failed');
      }
    });
  }

  Future<StorageDiagnostic> diagnostics() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      final Map<String, int> counts = <String, int>{};
      for (final String table in _tables) {
        final List<Map<String, Object?>> rows = await transaction.rawQuery(
          'SELECT COUNT(*) AS count FROM $table',
        );
        counts[table] = rows.single['count']! as int;
      }
      final List<Map<String, Object?>> integrity = await transaction.rawQuery(
        'PRAGMA quick_check',
      );
      final List<Map<String, Object?>> migrations = await transaction.query(
        'data_migrations',
        orderBy: 'schema_version DESC',
        limit: 1,
      );
      return StorageDiagnostic(
        schemaVersion: DatabaseSchema.currentVersion,
        integrityResult: integrity.single.values.single! as String,
        tableCounts: Map<String, int>.unmodifiable(counts),
        lastMigrationStatus: migrations.isEmpty
            ? 'none'
            : '${migrations.single['migration_id']}:'
                  '${migrations.single['status']}',
      );
    });
  }

  Future<void> deleteAllLocalData() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      for (final String table in _tables.reversed) {
        await transaction.delete(table);
      }
    });
  }

  Future<void> deleteSavedGames() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'saved_games',
        columns: const <String>['game_id'],
      );
      await transaction.delete('saved_games');
      for (final Map<String, Object?> row in rows) {
        await transaction.delete(
          'games',
          where: 'game_id = ?',
          whereArgs: <Object?>[row['game_id']],
        );
      }
    });
  }

  Future<void> deleteMatchHistory() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      await transaction.delete('match_history');
    });
  }

  Future<void> resetStatistics() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      await transaction.delete('statistics');
    });
  }

  Future<void> clearRecentOpponents() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      await transaction.delete('recent_opponents');
    });
  }

  Future<void> resetChallenges() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      await transaction.delete('challenge_events');
      await transaction.delete('challenge_progress');
      await transaction.delete('daily_challenges');
    });
  }

  Future<String> exportRewardLedger() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> balances = await transaction.query(
        'wallet_balances',
        orderBy: 'asset_type ASC',
      );
      final List<Map<String, Object?>> transactions = await transaction.query(
        'reward_transactions',
        orderBy: 'ledger_sequence ASC',
      );
      return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'formatVersion': snapshotVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'walletBalances': balances,
        'rewardTransactions': transactions,
      });
    });
  }

  Future<void> resetRewards() {
    final TransactionalDatabase database = _requireDatabase();
    return database.runTransaction((Transaction transaction) async {
      await transaction.delete('reward_transactions');
      await transaction.delete('wallet_balances');
    });
  }

  Map<String, Object?> _parse(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> ||
        decoded['formatVersion'] != snapshotVersion ||
        decoded['schemaVersion'] != DatabaseSchema.currentVersion ||
        decoded['createdAt'] is! String ||
        decoded['tables'] is! Map<String, Object?>) {
      throw const DataManagementFailure('invalid_snapshot');
    }
    DateTime.parse(decoded['createdAt']! as String);
    final Map<String, Object?> tables =
        decoded['tables']! as Map<String, Object?>;
    if (tables.keys.toSet().difference(_tables.toSet()).isNotEmpty ||
        _tables.any((String table) => tables[table] is! List<Object?>)) {
      throw const DataManagementFailure('invalid_snapshot_tables');
    }
    for (final Object? value in tables.values) {
      if ((value! as List<Object?>).any(
        (Object? row) => row is! Map<String, Object?>,
      )) {
        throw const DataManagementFailure('invalid_snapshot_rows');
      }
    }
    return decoded;
  }

  TransactionalDatabase _requireDatabase() {
    final TransactionalDatabase? database = _database;
    if (database == null) {
      throw const DataManagementFailure('database_unavailable');
    }
    return database;
  }
}
