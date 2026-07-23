import 'package:chess_master/app/app.dart';
import 'package:chess_master/app/app_config.dart';
import 'package:chess_master/core/database/app_database.dart';
import 'package:chess_master/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'runs splash, onboarding, and home without requiring an account',
    (WidgetTester tester) async {
      final AppConfig config = AppConfig(
        displayName: 'Chess-Master',
        creatorWatermark: 'Made by the Sanskar',
        repositoryUrl: Uri.parse('https://www.github.com/sanskarIN/Chess'),
        environment: 'test',
      );

      final _OpenTestDatabase database = _OpenTestDatabase();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            appDatabaseProvider.overrideWithValue(database),
          ],
          child: const ChessMasterApp(),
        ),
      );

      expect(find.text('Chess-Master'), findsOneWidget);
      expect(find.text('Open-source chess game'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Chess-Master'), findsOneWidget);
      expect(find.textContaining('Made by the Sanskar'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Choose how to play'), findsOneWidget);
      expect(database.settings['onboarding_completed'], 'true');
    },
  );
}

final class _OpenTestDatabase implements AppDatabase {
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
