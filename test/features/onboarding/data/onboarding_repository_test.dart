import 'package:chess_master/core/database/app_database.dart';
import 'package:chess_master/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseOnboardingRepository', () {
    test('shows onboarding until completion is stored', () async {
      final _SettingsDatabase database = _SettingsDatabase();
      final DatabaseOnboardingRepository repository =
          DatabaseOnboardingRepository(storage: database);

      expect(await repository.shouldShowOnboarding(), isTrue);

      await repository.setOnboardingCompleted(true);

      expect(await repository.shouldShowOnboarding(), isFalse);
      expect(database.settings['onboarding_completed'], 'true');
    });

    test('fails safely to showing onboarding without storage', () async {
      const DatabaseOnboardingRepository repository =
          DatabaseOnboardingRepository(storage: null);

      expect(await repository.shouldShowOnboarding(), isTrue);
      await repository.setOnboardingCompleted(true);
    });

    test('treats malformed preference types as incomplete', () async {
      final _SettingsDatabase database = _SettingsDatabase()
        ..settings['onboarding_completed'] = '"yes"';
      final DatabaseOnboardingRepository repository =
          DatabaseOnboardingRepository(storage: database);

      expect(await repository.shouldShowOnboarding(), isTrue);
    });

    test('recovers from invalid JSON by showing onboarding', () async {
      final _SettingsDatabase database = _SettingsDatabase()
        ..settings['onboarding_completed'] = '{broken';
      final DatabaseOnboardingRepository repository =
          DatabaseOnboardingRepository(storage: database);

      expect(await repository.shouldShowOnboarding(), isTrue);
    });
  });
}

final class _SettingsDatabase implements AppDatabase {
  final Map<String, String> settings = <String, String>{};

  @override
  bool get isOpen => true;

  @override
  int get schemaVersion => 1;

  @override
  Future<void> close() async {}

  @override
  Future<void> open() async {}

  @override
  Future<String?> readSetting(String key) async => settings[key];

  @override
  Future<void> writeSetting({
    required String key,
    required String valueJson,
    required String valueType,
  }) async {
    settings[key] = valueJson;
  }
}
