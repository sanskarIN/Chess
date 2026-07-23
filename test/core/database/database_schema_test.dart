import 'package:chess_master/core/database/database_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseSchema', () {
    test(
      'creates version three with foundation, economy, and training tables',
      () {
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
          'practice_progress',
        };
        final String schema = DatabaseSchema.creationStatements.join('\n');

        expect(DatabaseSchema.currentVersion, 3);
        for (final String table in requiredTables) {
          expect(
            schema,
            contains('CREATE TABLE $table'),
            reason: 'The schema must define $table.',
          );
        }
      },
    );

    test(
      'provides ordered v1 to v3 migrations and rejects future versions',
      () {
        final String migration = DatabaseSchema.statementsForUpgrade(
          1,
          3,
        ).join('\n');
        expect(migration, contains('CREATE TABLE wallet_balances'));
        expect(migration, contains('balance_before'));
        expect(migration, contains('integrity_hash'));
        expect(migration, contains('CREATE TABLE practice_progress'));

        expect(
          () => DatabaseSchema.statementsForUpgrade(3, 4),
          throwsUnsupportedError,
        );
      },
    );
  });
}
