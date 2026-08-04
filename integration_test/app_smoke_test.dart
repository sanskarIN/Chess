import 'package:chess_master/app/app.dart';
import 'package:chess_master/app/app_config.dart';
import 'package:chess_master/core/database/app_database.dart';
import 'package:chess_master/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'boots offline, completes onboarding, and reaches playable navigation',
    (WidgetTester tester) async {
      final _IntegrationDatabase database = _IntegrationDatabase();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig(
                displayName: 'Chess-Master',
                creatorWatermark: 'Made by the Sanskar',
                repositoryUrl: Uri.parse(
                  'https://www.github.com/sanskarIN/Chess',
                ),
                environment: 'integration-test',
              ),
            ),
            appDatabaseProvider.overrideWithValue(database),
          ],
          child: const ChessMasterApp(),
        ),
      );

      expect(find.text('Chess-Master'), findsOneWidget);
      expect(find.text('Open-source chess game'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Choose how to play'), findsOneWidget);
      expect(find.text('Play vs Computer'), findsOneWidget);
      expect(find.text('Local Two-Player'), findsOneWidget);
      expect(find.text('Match history'), findsOneWidget);
      expect(database.settings['onboarding_completed'], 'true');
    },
  );
}

final class _IntegrationDatabase implements AppDatabase {
  final Map<String, String> settings = <String, String>{};

  @override
  bool get isOpen => true;

  @override
  int get schemaVersion => 3;

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
