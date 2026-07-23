import 'package:chess_master/core/database/database_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseSchema', () {
    test('creates version two with foundation and economy tables', () {
      const Set<String> requiredTables = <String>{
        'app_settings',
        'player_profiles',
        'games',
        'moves',
        'saved_games',
        'match_history',
        'statistics',
        'daily_challenges',
        'challenge_progress',
        'reward_transactions',
        'achievements',
        'tutorial_progress',
        'recent_opponents',
        'developer_preferences',
        'data_migrations',
        'wallet_balances',
        'challenge_events',
      };
      final String schema = DatabaseSchema.creationStatements.join('\n');

      expect(DatabaseSchema.currentVersion, 2);
      for (final String table in requiredTables) {
        expect(
          schema,
          contains('CREATE TABLE $table'),
          reason: 'The schema must define $table.',
        );
      }
    });

    test('provides the v1 to v2 migration and rejects future versions', () {
      final String migration = DatabaseSchema.statementsForUpgrade(
        1,
        2,
      ).join('\n');
      expect(migration, contains('CREATE TABLE wallet_balances'));
      expect(migration, contains('balance_before'));
      expect(migration, contains('integrity_hash'));

      expect(
        () => DatabaseSchema.statementsForUpgrade(2, 3),
        throwsUnsupportedError,
      );
    });
  });
}
