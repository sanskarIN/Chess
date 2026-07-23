import 'dart:async';

import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/presentation/game_screen.dart';
import 'package:chess_master/features/computer_player/application/engine_service.dart';
import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_difficulty.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_chess_engine.dart';
import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('locks the board while thinking and opens with White for Black', (
    WidgetTester tester,
  ) async {
    final Completer<void> searchGate = Completer<void>();
    final FakeChessEngine engine = FakeChessEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.beginner,
      ),
      selector: (_) => Move.fromUci('e2e4'),
      searchGate: searchGate,
    );
    final GameSetup setup = GameSetup.computer(
      playerName: 'Ada',
      defaultPlayerName: 'You',
      computerName: 'Computer',
      sideChoice: PlayerSideChoice.black,
      timeControl: TimeControl.none,
      difficulty: ComputerDifficulty.beginner,
      hintsEnabled: false,
    );

    await tester.pumpWidget(
      localizedTestApp(
        GameScreen(
          setup: setup,
          engineService: EngineService(ownedEngine: engine),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Computer is thinking'), findsWidgets);
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey<String>('square-e2')))
          .properties
          .enabled,
      isFalse,
    );

    searchGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.text('e4'), findsOneWidget);
    expect(find.text('Black to move'), findsWidgets);
    expect(find.text('Built-in local computer ready'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
