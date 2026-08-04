import 'package:chess_master/app/app_theme.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/history/application/match_history_providers.dart';
import 'package:chess_master/features/history/data/in_memory_match_history_repository.dart';
import 'package:chess_master/features/history/presentation/history_statistics_screen.dart';
import 'package:chess_master/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders filterable history, statistics, and one-time achievements',
    (WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(1200, 1600)
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });
      final InMemoryMatchHistoryRepository repository =
          InMemoryMatchHistoryRepository();
      final DateTime completedAt = DateTime.utc(2026, 7, 30, 12);
      await repository.recordCompletedMatch(
        setup: _setup(),
        game: _game(),
        startedAt: completedAt.subtract(const Duration(seconds: 30)),
        completedAt: completedAt,
        hintCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchHistoryRepositoryProvider.overrideWithValue(repository),
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
            home: const HistoryStatisticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('History, statistics, and achievements'),
        findsOneWidget,
      );
      expect(find.text('Computer'), findsWidgets);
      expect(find.text('Win'), findsOneWidget);
      expect(find.text('Review this completed game'), findsOneWidget);

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.text('Games played'), findsOneWidget);
      expect(find.text('Fastest win'), findsOneWidget);
      expect(find.text('Reset statistics'), findsOneWidget);

      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();
      expect(find.text('First Move'), findsOneWidget);
      expect(find.text('First Win'), findsOneWidget);
      expect(find.text('Unlocked'), findsWidgets);
      expect(find.text('Fifty Games Played'), findsOneWidget);
    },
  );
}

ChessGame _game() {
  return ChessGame(gameId: 'history-widget')
    ..play(Move.fromUci('f2f3'))
    ..play(Move.fromUci('e7e5'))
    ..play(Move.fromUci('g2g4'))
    ..play(Move.fromUci('d8h4'));
}

GameSetup _setup() {
  return GameSetup.computer(
    playerName: 'Alice',
    defaultPlayerName: 'Player',
    computerName: 'Computer',
    sideChoice: PlayerSideChoice.black,
    timeControl: TimeControl.threePlusTwo,
    difficulty: ComputerDifficulty.expert,
    hintsEnabled: true,
  );
}
