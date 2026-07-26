import 'package:chess_master/app/app_theme.dart';
import 'package:chess_master/features/settings/application/settings_providers.dart';
import 'package:chess_master/features/settings/data/settings_repository.dart';
import 'package:chess_master/features/settings/domain/app_settings.dart';
import 'package:chess_master/features/settings/presentation/data_management_screen.dart';
import 'package:chess_master/features/settings/presentation/developer_options_screen.dart';
import 'package:chess_master/features/settings/presentation/settings_screen.dart';
import 'package:chess_master/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings exposes every required group and persists toggles', (
    WidgetTester tester,
  ) async {
    final _MemorySettingsRepository repository = _MemorySettingsRepository(
      AppSettings.defaults(),
    );
    await tester.pumpWidget(_testApp(const SettingsScreen(), repository));
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    final Finder exitToggle = find.widgetWithText(
      SwitchListTile,
      'Confirm before exit',
    );
    expect(exitToggle, findsOneWidget);
    await tester.tap(exitToggle);
    await tester.pumpAndSettle();
    expect(repository.value.enabled(SettingFlag.confirmBeforeExit), isFalse);
    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    final Finder settingsList = find.byType(Scrollable).first;
    for (final String group in <String>[
      'Appearance',
      'Gameplay',
      'Sound and haptics',
      'Computer opponent',
      'Multiplayer',
      'Daily challenges and rewards',
      'Language',
      'Accessibility',
      'Privacy and data',
      'About',
      'Follow Sanskar or Creator',
    ]) {
      if (find.text(group).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text(group),
          260,
          scrollable: settingsList,
        );
      }
      expect(find.text(group), findsOneWidget);
    }
  });

  testWidgets('developer options stay guarded until persisted unlock', (
    WidgetTester tester,
  ) async {
    final _MemorySettingsRepository locked = _MemorySettingsRepository(
      AppSettings.defaults(),
    );
    await tester.pumpWidget(_testApp(const DeveloperOptionsScreen(), locked));
    await tester.pumpAndSettle();

    expect(
      find.text('Tap seven times to unlock documented developer options.'),
      findsOneWidget,
    );

    final _MemorySettingsRepository unlocked = _MemorySettingsRepository(
      AppSettings.defaults().copyWith(developerOptionsEnabled: true),
    );
    await tester.pumpWidget(_testApp(const DeveloperOptionsScreen(), unlocked));
    await tester.pumpAndSettle();

    final Finder developerList = find.byType(Scrollable).first;
    for (final String group in <String>[
      'Application diagnostics',
      'Debug controls',
      'Chess tools',
      'Economy tools',
      'Challenge tools',
      'Multiplayer tools',
      'Localization tools',
      'Storage tools',
      'Feature flags',
      'Open-source information',
    ]) {
      if (find.text(group).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text(group),
          260,
          scrollable: developerList,
        );
      }
      expect(find.text(group), findsOneWidget);
    }
  });

  testWidgets(
    'data management exposes all resets and typed delete confirmation',
    (WidgetTester tester) async {
      final _MemorySettingsRepository repository = _MemorySettingsRepository(
        AppSettings.defaults(),
      );
      await tester.pumpWidget(
        _testApp(const DataManagementScreen(), repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('View local data'), findsOneWidget);
      expect(find.text('Export local data'), findsOneWidget);
      expect(find.text('Import local data'), findsOneWidget);
      final Finder dataList = find.byType(Scrollable).first;
      for (final String action in <String>[
        'Delete match history',
        'Reset statistics',
        'Delete saved games',
        'Reset challenges',
        'Reset coins and hints',
        'Clear recent opponents',
        'Export reward ledger',
        'Delete all local application data',
      ]) {
        if (find.text(action).evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            find.text(action),
            220,
            scrollable: dataList,
          );
        }
        expect(find.text(action), findsOneWidget);
      }

      await tester.tap(find.text('Delete all local application data'));
      await tester.pumpAndSettle();
      expect(find.text('Type DELETE to confirm'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      expect(find.text('Type DELETE to confirm'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The local data action failed validation and made no changes.',
        ),
        findsOneWidget,
      );
    },
  );
}

Widget _testApp(Widget home, SettingsRepository repository) {
  return ProviderScope(
    overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
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
