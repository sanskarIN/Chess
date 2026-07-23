import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../logging/app_logger.dart';
import 'app_database.dart';
import 'database_schema.dart';

final class SqfliteAppDatabase implements AppDatabase {
  SqfliteAppDatabase({required AppLogger logger}) : _logger = logger;

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
          for (final String statement in DatabaseSchema.version1Statements) {
            await transaction.execute(statement);
          }
          await transaction.insert('data_migrations', <String, Object?>{
            'migration_id': 'schema_v1',
            'schema_version': 1,
            'status': 'completed',
            'started_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            'completed_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            'details': 'Initial local database schema.',
          });
        });
      },
      onUpgrade: (Database database, int oldVersion, int newVersion) async {
        await database.transaction((Transaction transaction) async {
          for (final String statement
              in DatabaseSchema.statementsForUpgrade(oldVersion, newVersion)) {
            await transaction.execute(statement);
          }
        });
      },
      onDowngrade: (
        Database database,
        int oldVersion,
        int newVersion,
      ) async {
        throw UnsupportedError(
          'Database downgrade from $oldVersion to $newVersion is not supported.',
        );
      },
      onOpen: (Database database) async {
        final List<Map<String, Object?>> check = await database.rawQuery(
          'PRAGMA quick_check',
        );
        final Object? result = check.length == 1 && check.first.values.length == 1
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
}
