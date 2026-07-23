import 'package:chess_master/app/app.dart';
import 'package:chess_master/app/app_config.dart';
import 'package:chess_master/core/database/app_database.dart';
import 'package:chess_master/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the localized foundation status and creator watermark', (
    WidgetTester tester,
  ) async {
    final AppConfig config = AppConfig(
      displayName: 'Chess-Master',
      creatorWatermark: 'Made by the Sanskar',
      repositoryUrl: Uri.parse('https://www.github.com/sanskarIN/Chess'),
      environment: 'test',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWithValue(config),
          appDatabaseProvider.overrideWithValue(_OpenTestDatabase()),
        ],
        child: const ChessMasterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chess-Master'), findsOneWidget);
    expect(find.text('Open-source chess game'), findsOneWidget);
    expect(find.textContaining('Made by the Sanskar'), findsOneWidget);
    expect(find.text('Local database ready'), findsOneWidget);
  });
}

final class _OpenTestDatabase implements AppDatabase {
  @override
  bool get isOpen => true;

  @override
  int get schemaVersion => 1;

  @override
  Future<void> close() async {}

  @override
  Future<void> open() async {}
}
