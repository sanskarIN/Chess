import 'package:chess_master/app/app_theme.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/saved_games/application/saved_game_providers.dart';
import 'package:chess_master/features/saved_games/data/in_memory_saved_game_repository.dart';
import 'package:chess_master/features/saved_games/domain/saved_game.dart';
import 'package:chess_master/features/saved_games/presentation/review_screen.dart';
import 'package:chess_master/features/saved_games/presentation/saved_games_screen.dart';
import 'package:chess_master/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved-games screen renders persisted local metadata', (
    WidgetTester tester,
  ) async {
    _useLargeSurface(tester);
    final InMemorySavedGameRepository repository =
        InMemorySavedGameRepository();
    final ChessGame game = ChessGame(gameId: 'saved-widget')
      ..play(Move.fromUci('e2e4'));
    await repository.save(
      title: 'Training save',
      setup: _setup(),
      game: game,
      now: DateTime.utc(2026, 7, 23),
    );

    await tester.pumpWidget(_savedApp(const SavedGamesScreen(), repository));
    await tester.pumpAndSettle();

    expect(find.text('Training save'), findsOneWidget);
    expect(find.textContaining('Alice · Bob'), findsOneWidget);
    expect(find.text('Import FEN'), findsOneWidget);
    expect(find.text('Import PGN'), findsOneWidget);
  });

  testWidgets('review screen steps between first and last positions', (
    WidgetTester tester,
  ) async {
    _useLargeSurface(tester);
    final ChessGame game = ChessGame(gameId: 'review-widget')
      ..play(Move.fromUci('e2e4'))
      ..play(Move.fromUci('e7e5'));
    await tester.pumpWidget(
      _app(
        ReviewScreen(
          launch: ReviewLaunch(game: game, setup: _setup()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Move 2 of 2'), findsOneWidget);
    await tester.tap(find.byTooltip('First position'));
    await tester.pump();
    expect(find.text('Move 0 of 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Last position'));
    await tester.pump();
    expect(find.text('Move 2 of 2'), findsOneWidget);
    expect(
      find.text(
        'Local evaluation is available when analysis or hints are enabled for this saved game.',
      ),
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

GameSetup _setup() {
  return GameSetup.local(
    playerOneName: 'Alice',
    playerTwoName: 'Bob',
    defaultPlayerOneName: 'Player 1',
    defaultPlayerTwoName: 'Player 2',
    playerOneSide: PlayerSideChoice.white,
    timeControl: TimeControl.none,
  );
}

Widget _savedApp(Widget home, InMemorySavedGameRepository repository) {
  return ProviderScope(
    overrides: [savedGameRepositoryProvider.overrideWithValue(repository)],
    child: _materialApp(home),
  );
}

Widget _app(Widget home) {
  return ProviderScope(child: _materialApp(home));
}

Widget _materialApp(Widget home) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
