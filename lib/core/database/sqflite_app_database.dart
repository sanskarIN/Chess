import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../logging/app_logger.dart';
import 'app_database.dart';
import 'database_schema.dart';
import 'transactional_database.dart';

final class SqfliteAppDatabase implements AppDatabase, TransactionalDatabase {
  SqfliteAppDatabase({required AppLogger appLogger}) : _logger = appLogger;

  final AppLogger _logger;
  Database? _database;

  @override
  int get schemaVersion => DatabaseSchema.currentVersion;

  @override
  bool get isOpen => _database?.isOpen ?? false;

  @override
  Future<void> open() async {
    if (isOpen) {
      return;
    }

    final String databasesPath = await getDatabasesPath();
    final String databasePath = path.join(
      databasesPath,
      DatabaseSchema.fileName,
    );

    _database = await openDatabase(
      databasePath,
      version: schemaVersion,
      onConfigure: (Database database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await database.execute('PRAGMA busy_timeout = 5000');
      },
      onCreate: (Database database, int version) async {
        await database.transaction((Transaction transaction) async {
          for (final String statement in DatabaseSchema.creationStatements) {
            await transaction.execute(statement);
          }
          final int now = DateTime.now().toUtc().millisecondsSinceEpoch;
          await transaction.insert('data_migrations', <String, Object?>{
            'migration_id': 'schema_v1',
            'schema_version': 1,
            'status': 'completed',
            'started_at': now,
            'completed_at': now,
            'details': 'Initial local database schema.',
          });
          await transaction.insert('data_migrations', <String, Object?>{
            'migration_id': 'schema_v2',
            'schema_version': 2,
            'status': 'completed',
            'started_at': now,
            'completed_at': now,
            'details': 'Atomic challenge wallet and reward ledger.',
          });
        });
      },
      onUpgrade: (Database database, int oldVersion, int newVersion) async {
        await database.transaction((Transaction transaction) async {
          for (final String statement in DatabaseSchema.statementsForUpgrade(
            oldVersion,
            newVersion,
          )) {
            await transaction.execute(statement);
          }
          final int now = DateTime.now().toUtc().millisecondsSinceEpoch;
          if (oldVersion < 2 && newVersion >= 2) {
            await transaction.insert('data_migrations', <String, Object?>{
              'migration_id': 'schema_v2',
              'schema_version': 2,
              'status': 'completed',
              'started_at': now,
              'completed_at': now,
              'details': 'Atomic challenge wallet and reward ledger.',
            });
          }
        });
      },
      onDowngrade: (Database database, int oldVersion, int newVersion) async {
        throw UnsupportedError(
          'Database downgrade from $oldVersion to $newVersion is not supported.',
        );
      },
      onOpen: (Database database) async {
        final List<Map<String, Object?>> check = await database.rawQuery(
          'PRAGMA quick_check',
        );
        final Object? result =
            check.length == 1 && check.first.values.length == 1
            ? check.first.values.first
            : null;
        if (result != 'ok') {
          throw StateError('SQLite integrity check failed.');
        }
      },
    );

    _logger.info(
      'database.opened',
      fields: <String, Object?>{'schemaVersion': schemaVersion},
    );
  }

  @override
  Future<void> close() async {
    final Database? database = _database;
    _database = null;
    if (database == null || !database.isOpen) {
      return;
    }

    await database.close();
    _logger.info('database.closed');
  }

  @override
  Future<String?> readSetting(String key) async {
    final Database database = _requireOpenDatabase();
    final List<Map<String, Object?>> rows = await database.query(
      'app_settings',
      columns: const <String>['value_json'],
      where: 'setting_key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.single['value_json'] as String?;
  }

  @override
  Future<void> writeSetting({
    required String key,
    required String valueJson,
    required String valueType,
  }) async {
    final Database database = _requireOpenDatabase();
    await database.insert('app_settings', <String, Object?>{
      'setting_key': key,
      'value_json': valueJson,
      'value_type': valueType,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return _requireOpenDatabase().transaction<T>(action);
  }

  Database _requireOpenDatabase() {
    final Database? database = _database;
    if (database == null || !database.isOpen) {
      throw StateError('The application database is not open.');
    }
    return database;
  }
}
