import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/database_providers.dart';
import '../data/settings_repository.dart';
import 'settings_controller.dart';

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) {
      return DatabaseSettingsRepository(ref.watch(appDatabaseProvider));
    });

final ChangeNotifierProvider<SettingsController> settingsControllerProvider =
    ChangeNotifierProvider<SettingsController>((Ref ref) {
      final SettingsController controller = SettingsController(
        repository: ref.watch(settingsRepositoryProvider),
      );
      unawaited(controller.initialize());
      return controller;
    });
