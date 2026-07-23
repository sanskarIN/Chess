import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

final Provider<OnboardingRepository> onboardingRepositoryProvider =
    Provider<OnboardingRepository>((Ref ref) {
      return DatabaseOnboardingRepository(
        storage: ref.watch(appDatabaseProvider),
      );
    });

abstract interface class OnboardingRepository {
  Future<bool> shouldShowOnboarding();
  Future<void> setOnboardingCompleted(bool completed);
}

final class DatabaseOnboardingRepository implements OnboardingRepository {
  const DatabaseOnboardingRepository({required AppDatabase? storage})
    : _database = storage;

  static const String _settingKey = 'onboarding_completed';

  final AppDatabase? _database;

  @override
  Future<bool> shouldShowOnboarding() async {
    final AppDatabase? database = _database;
    if (database == null || !database.isOpen) {
      return true;
    }
    final String? storedValue = await database.readSetting(_settingKey);
    if (storedValue == null) {
      return true;
    }
    try {
      final Object? decoded = jsonDecode(storedValue);
      return decoded is! bool || !decoded;
    } on FormatException {
      return true;
    }
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final AppDatabase? database = _database;
    if (database == null || !database.isOpen) {
      return;
    }
    await database.writeSetting(
      key: _settingKey,
      valueJson: jsonEncode(completed),
      valueType: 'bool',
    );
  }
}
