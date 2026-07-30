import 'package:chess_master/app/app.dart';
import 'package:chess_master/app/app_config.dart';
import 'package:chess_master/features/settings/application/settings_providers.dart';
import 'package:chess_master/features/settings/data/settings_repository.dart';
import 'package:chess_master/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('an uncommon RTL locale mirrors navigation without restarting', (
    WidgetTester tester,
  ) async {
    final _MemorySettingsRepository repository = _MemorySettingsRepository(
      AppSettings.defaults().copyWith(localeCode: 'ks'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              displayName: 'Chess-Master',
              creatorWatermark: 'Made by the Sanskar',
              repositoryUrl: Uri.parse('https://github.com/sanskarIN/Chess'),
              environment: 'test',
            ),
          ),
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const ChessMasterApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final BuildContext scaffold = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(scaffold), TextDirection.rtl);
    expect(Localizations.localeOf(scaffold).languageCode, 'ks');
    expect(tester.takeException(), isNull);
  });
}

final class _MemorySettingsRepository implements SettingsRepository {
  _MemorySettingsRepository(this.value);

  AppSettings value;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> reset() async {
    value = AppSettings.defaults();
  }

  @override
  Future<void> save(AppSettings settings) async {
    value = settings;
  }
}
