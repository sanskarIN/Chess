import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/presentation/game_screen.dart';
import 'package:chess_master/features/local_multiplayer/domain/local_match_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_monotonic_time_source.dart';
import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets(
    'shows a live clock and requires named opponent approval for undo',
    (WidgetTester tester) async {
      final FakeMonotonicTimeSource time = FakeMonotonicTimeSource();
      final GameSetup setup = GameSetup.local(
        playerOneName: 'Ada',
        playerTwoName: 'Grace',
        defaultPlayerOneName: 'Player 1',
        defaultPlayerTwoName: 'Player 2',
        playerOneSide: PlayerSideChoice.white,
        timeControl: const TimeControl(id: '5+2-test', initialSeconds: 5),
        undoPolicy: LocalUndoPolicy.requireOpponentApproval,
      );

      await tester.pumpWidget(
        localizedTestApp(GameScreen(setup: setup, clockTimeSource: time)),
      );
      await tester.pump();
      expect(find.text('00:05'), findsNWidgets(2));

      time.advance(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('00:03'), findsOneWidget);

      await _tapSquare(tester, 'e2');
      await _tapSquare(tester, 'e4');
      expect(find.text('e4'), findsOneWidget);

      final Finder undo = find.byTooltip('Undo');
      await tester.ensureVisible(undo);
      await tester.tap(undo);
      await tester.pumpAndSettle();

      expect(find.text('Undo request'), findsOneWidget);
      expect(
        find.text(
          'Grace requests an undo. Ada must approve before the previous move and clock state are restored.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(find.text('e4'), findsNothing);
      expect(find.text('00:05'), findsNWidgets(2));
    },
  );

  testWidgets('honors fixed Black and automatic rotation orientations', (
    WidgetTester tester,
  ) async {
    GameSetup setup(LocalBoardOrientation orientation) {
      return GameSetup.local(
        playerOneName: 'Ada',
        playerTwoName: 'Grace',
        defaultPlayerOneName: 'Player 1',
        defaultPlayerTwoName: 'Player 2',
        playerOneSide: PlayerSideChoice.white,
        timeControl: TimeControl.none,
        boardOrientation: orientation,
        undoPolicy: LocalUndoPolicy.alwaysAllow,
      );
    }

    await tester.pumpWidget(
      localizedTestApp(
        GameScreen(
          key: const ValueKey<String>('fixed-black-game'),
          setup: setup(LocalBoardOrientation.blackAtBottom),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('square-h1'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey<String>('square-a8'))).dy,
      ),
    );

    await tester.pumpWidget(
      localizedTestApp(
        GameScreen(
          key: const ValueKey<String>('rotating-game'),
          setup: setup(LocalBoardOrientation.rotateAfterMove),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('square-a8'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey<String>('square-h1'))).dy,
      ),
    );

    await _tapSquare(tester, 'e2');
    await _tapSquare(tester, 'e4');
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('square-h1'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey<String>('square-a8'))).dy,
      ),
    );
  });
}

Future<void> _tapSquare(WidgetTester tester, String square) async {
  final Finder finder = find.byKey(ValueKey<String>('square-$square'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}
