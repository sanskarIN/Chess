import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/chess/presentation/widgets/match_result_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows complete match summary and returns a selected action', (
    WidgetTester tester,
  ) async {
    MatchResultAction? selected;
    await tester.pumpWidget(
      localizedTestApp(
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () async {
                  selected = await showDialog<MatchResultAction>(
                    context: context,
                    builder: (BuildContext context) {
                      return const MatchResultDialog(
                        result: GameResult.whiteWin(GameResultReason.checkmate),
                        duration: Duration(minutes: 4, seconds: 12),
                        moveCount: 37,
                        captureCount: 8,
                        hintCount: 1,
                      );
                    },
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('White wins'), findsOneWidget);
    expect(find.text('Checkmate'), findsOneWidget);
    expect(find.text('04:12'), findsOneWidget);
    expect(find.text('37'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Rematch'), findsOneWidget);
    expect(find.text('Review game'), findsOneWidget);
    expect(find.text('Copy PGN'), findsOneWidget);
    expect(find.text('Return home'), findsOneWidget);

    await tester.tap(find.text('Review game'));
    await tester.pumpAndSettle();
    expect(selected, MatchResultAction.review);
  });
}
