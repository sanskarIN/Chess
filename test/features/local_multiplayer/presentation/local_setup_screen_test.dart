import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/presentation/player_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('offers names, clocks, orientation, and undo policy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(const PlayerSetupScreen(mode: GameMode.local)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Player 1 name (optional)'), findsOneWidget);
    expect(find.text('Player 2 name (optional)'), findsOneWidget);
    expect(find.text('Time control'), findsWidgets);
    expect(find.text('Board orientation'), findsOneWidget);
    expect(find.text('White at bottom'), findsOneWidget);
    expect(find.text('Undo policy'), findsOneWidget);
    expect(find.text('Ask the opponent'), findsOneWidget);
    expect(find.text('Skip names'), findsOneWidget);
    expect(find.text('Start game'), findsOneWidget);
  });
}
