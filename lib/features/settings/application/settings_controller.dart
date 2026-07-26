import 'package:flutter/foundation.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final class SettingsController extends ChangeNotifier {
  SettingsController({required this.repository});

  final SettingsRepository repository;
  AppSettings _settings = AppSettings.defaults();
  bool _initialized = false;
  bool _busy = false;
  int _versionTapCount = 0;

  AppSettings get settings => _settings;
  bool get initialized => _initialized;
  bool get busy => _busy;
  int get remainingDeveloperTaps => (7 - _versionTapCount).clamp(0, 7);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _settings = await repository.load();
    _initialized = true;
    notifyListeners();
  }

  Future<void> setFlag(SettingFlag flag, bool enabled) {
    final Set<SettingFlag> flags = <SettingFlag>{..._settings.enabledFlags};
    enabled ? flags.add(flag) : flags.remove(flag);
    return update(_settings.copyWith(enabledFlags: flags));
  }

  Future<void> setFeatureFlag(TypedFeatureFlag flag, bool enabled) {
    final Set<TypedFeatureFlag> flags = <TypedFeatureFlag>{
      ..._settings.featureFlags,
    };
    enabled ? flags.add(flag) : flags.remove(flag);
    return update(_settings.copyWith(featureFlags: flags));
  }

  Future<void> update(AppSettings value) async {
    _busy = true;
    _settings = value;
    notifyListeners();
    try {
      await repository.save(value);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> registerVersionTap() async {
    if (_settings.developerOptionsEnabled) {
      return true;
    }
    _versionTapCount++;
    if (_versionTapCount < 7) {
      notifyListeners();
      return false;
    }
    await update(_settings.copyWith(developerOptionsEnabled: true));
    return true;
  }

  Future<void> reset() async {
    _versionTapCount = 0;
    await repository.reset();
    _settings = AppSettings.defaults();
    notifyListeners();
  }
}
