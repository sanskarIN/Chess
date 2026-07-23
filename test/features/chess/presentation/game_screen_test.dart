import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/presentation/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('plays, records, undoes, and redoes a local move', (
    WidgetTester tester,
  ) async {
    final GameSetup setup = GameSetup.local(
      playerOneName: 'Ada',
      playerTwoName: 'Grace',
      defaultPlayerOneName: 'Player 1',
      defaultPlayerTwoName: 'Player 2',
      playerOneSide: PlayerSideChoice.white,
      timeControl: TimeControl.none,
      rotateAfterMove: false,
    );

    await tester.pumpWidget(localizedTestApp(GameScreen(setup: setup)));
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('No moves yet. Select a piece to begin.'), findsOneWidget);

    final Finder e2 = find.byKey(const ValueKey<String>('square-e2'));
    final Finder e4 = find.byKey(const ValueKey<String>('square-e4'));
    await tester.ensureVisible(e2);
    await tester.tap(e2);
    await tester.pump();
    await tester.ensureVisible(e4);
    await tester.tap(e4);
    await tester.pumpAndSettle();

    expect(find.text('e4'), findsOneWidget);

    final Finder undo = find.byTooltip('Undo');
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(find.text('e4'), findsNothing);

    final Finder redo = find.byTooltip('Redo');
    await tester.ensureVisible(redo);
    await tester.tap(redo);
    await tester.pumpAndSettle();
    expect(find.text('e4'), findsOneWidget);
  });
}
