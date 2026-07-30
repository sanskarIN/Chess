import 'package:chess_master/app/app_theme.dart';
import 'package:chess_master/features/settings/application/settings_providers.dart';
import 'package:chess_master/features/settings/data/settings_repository.dart';
import 'package:chess_master/features/settings/domain/app_settings.dart';
import 'package:chess_master/features/settings/presentation/language_selector_screen.dart';
import 'package:chess_master/l10n/app_localizations.dart';
import 'package:chess_master/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('searches native/English names and persists a live selection', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _MemorySettingsRepository repository = _MemorySettingsRepository(
      AppSettings.defaults(),
    );
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('language-system')), findsOne);
    await tester.enterText(
      find.byKey(const ValueKey<String>('language-search')),
      'Urdu',
    );
    await tester.pump();

    expect(find.text('اردو'), findsOne);
    expect(find.text('Urdu'), findsWidgets);
    expect(find.text('অসমীয়া'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('language-ur')));
    await tester.pumpAndSettle();

    expect(repository.value.localeCode, 'ur');
    final node = tester.getSemantics(
      find.byKey(const ValueKey<String>('language-ur')),
    );
    expect(node.label, contains('اردو'));
    expect(node.label, contains('Urdu'));
    semantics.dispose();
  });

  testWidgets('shows all requested options and survives expanded text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _MemorySettingsRepository repository = _MemorySettingsRepository(
      AppSettings.defaults(),
    );
    await tester.pumpWidget(_app(repository, textScale: 2));
    await tester.pumpAndSettle();

    for (final SupportedLanguage language in SupportedLanguages.all) {
      await tester.enterText(
        find.byKey(const ValueKey<String>('language-search')),
        language.englishName,
      );
      await tester.pump();
      expect(find.byKey(ValueKey<String>('language-${language.id}')), findsOne);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders every native name through the fallback font stack', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: <Widget>[
                for (final SupportedLanguage language in SupportedLanguages.all)
                  Text(language.nativeName),
              ],
            ),
          ),
        ),
      ),
    );

    for (final SupportedLanguage language in SupportedLanguages.all) {
      expect(find.text(language.nativeName), findsOne);
    }
    expect(tester.takeException(), isNull);
  });
}

Widget _app(_MemorySettingsRepository repository, {double textScale = 1}) {
  return ProviderScope(
    overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LanguageSelectorScreen(),
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
