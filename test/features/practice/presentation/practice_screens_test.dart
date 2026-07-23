import 'package:chess_master/app/app_theme.dart';
import 'package:chess_master/features/challenges/application/challenge_providers.dart';
import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/practice/application/practice_providers.dart';
import 'package:chess_master/features/practice/data/asset_training_puzzle_repository.dart';
import 'package:chess_master/features/practice/data/in_memory_learning_progress_repository.dart';
import 'package:chess_master/features/practice/data/tutorial_catalog.dart';
import 'package:chess_master/features/practice/presentation/practice_hub_screen.dart';
import 'package:chess_master/features/practice/presentation/puzzle_screen.dart';
import 'package:chess_master/features/practice/presentation/tutorial_lesson_screen.dart';
import 'package:chess_master/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tutorial lesson validates board interaction and shows success', (
    WidgetTester tester,
  ) async {
    _useLargeSurface(tester);
    final lesson = TutorialCatalog.lessons.singleWhere(
      (value) => value.id == 'pawn-movement',
    );
    await tester.pumpWidget(_app(TutorialLessonScreen(lesson: lesson)));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    await tester.pumpAndSettle();

    expect(find.text('Lesson complete'), findsOneWidget);
    expect(find.text('First completion reward: 5 coins'), findsOneWidget);
  });

  testWidgets('puzzle screen validates a solution on the interactive board', (
    WidgetTester tester,
  ) async {
    _useLargeSurface(tester);
    final puzzle = (await const AssetTrainingPuzzleRepository().load()).first;
    await tester.pumpWidget(_app(PuzzleScreen(puzzle: puzzle)));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('square-d8')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-h4')));
    await tester.pumpAndSettle();

    expect(find.text('Exercise solved'), findsOneWidget);
    expect(find.text('First completion reward: 10 coins'), findsOneWidget);
  });

  testWidgets('practice hub rejects malformed custom FEN', (
    WidgetTester tester,
  ) async {
    _useLargeSurface(tester);
    await tester.pumpWidget(_app(const PracticeHubScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Load custom FEN'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Load custom FEN'));
    await tester.pump();
    await tester.tap(find.text('Load custom FEN'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'invalid fen');
    await tester.tap(find.text('Load position'));
    await tester.pump();

    expect(
      find.text('That FEN is invalid or internally inconsistent.'),
      findsOneWidget,
    );
  });
}

void _useLargeSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1200, 1400)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

Widget _app(Widget home) {
  return ProviderScope(
    overrides: [
      learningProgressRepositoryProvider.overrideWithValue(
        InMemoryLearningProgressRepository(),
      ),
      challengeRepositoryProvider.overrideWithValue(
        InMemoryChallengeRepository(),
      ),
    ],
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
