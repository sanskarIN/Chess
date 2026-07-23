import 'package:chess_master/core/database/database_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseSchema', () {
    test('starts at version one with every required foundation table', () {
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
      };
      final String schema = DatabaseSchema.version1Statements.join('\n');

      expect(DatabaseSchema.currentVersion, 1);
      for (final String table in requiredTables) {
        expect(
          schema,
          contains('CREATE TABLE $table'),
          reason: 'The schema must define $table.',
        );
      }
    });

    test('rejects migrations beyond the application schema', () {
      expect(
        () => DatabaseSchema.statementsForUpgrade(1, 2),
        throwsUnsupportedError,
      );
    });
  });
}
