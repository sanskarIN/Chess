import 'package:chess_master/features/settings/application/settings_controller.dart';
import 'package:chess_master/features/settings/data/settings_repository.dart';
import 'package:chess_master/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsController', () {
    test('loads, updates, persists, and resets typed settings', () async {
      final _MemorySettingsRepository repository = _MemorySettingsRepository(
        AppSettings.defaults().copyWith(theme: AppThemePreference.dark),
      );
      final SettingsController controller = SettingsController(
        repository: repository,
      );

      await controller.initialize();
      expect(controller.initialized, isTrue);
      expect(controller.settings.theme, AppThemePreference.dark);

      await controller.setFlag(SettingFlag.showLegalMoves, false);
      await controller.setFeatureFlag(TypedFeatureFlag.debugOverlay, true);

      expect(controller.settings.enabled(SettingFlag.showLegalMoves), isFalse);
      expect(
        controller.settings.featureEnabled(TypedFeatureFlag.debugOverlay),
        isTrue,
      );
      expect(repository.saved, same(controller.settings));

      await controller.reset();
      expect(controller.settings.theme, AppThemePreference.system);
      expect(controller.settings.developerOptionsEnabled, isFalse);
      expect(repository.resetCount, 1);
    });

    test('unlocks developer options on exactly seven version taps', () async {
      final _MemorySettingsRepository repository = _MemorySettingsRepository(
        AppSettings.defaults(),
      );
      final SettingsController controller = SettingsController(
        repository: repository,
      );
      await controller.initialize();

      for (int count = 6; count >= 1; count--) {
        expect(await controller.registerVersionTap(), isFalse);
        expect(controller.remainingDeveloperTaps, count);
      }
      expect(await controller.registerVersionTap(), isTrue);
      expect(controller.remainingDeveloperTaps, 0);
      expect(controller.settings.developerOptionsEnabled, isTrue);
      expect(repository.saved?.developerOptionsEnabled, isTrue);

      expect(await controller.registerVersionTap(), isTrue);
      expect(controller.remainingDeveloperTaps, 0);
    });

    test('initialization is idempotent', () async {
      final _MemorySettingsRepository repository = _MemorySettingsRepository(
        AppSettings.defaults(),
      );
      final SettingsController controller = SettingsController(
        repository: repository,
      );

      await controller.initialize();
      await controller.initialize();

      expect(repository.loadCount, 1);
    });
  });
}

final class _MemorySettingsRepository implements SettingsRepository {
  _MemorySettingsRepository(this.value);

  AppSettings value;
  AppSettings? saved;
  int loadCount = 0;
  int resetCount = 0;

  @override
  Future<AppSettings> load() async {
    loadCount++;
    return value;
  }

  @override
  Future<void> reset() async {
    resetCount++;
    value = AppSettings.defaults();
  }

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
    saved = settings;
  }
}
