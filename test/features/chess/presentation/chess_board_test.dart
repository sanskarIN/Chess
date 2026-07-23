import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/position.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/chess/domain/rules/move_generator.dart';
import 'package:chess_master/features/chess/presentation/widgets/chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('announces pieces and exposes legal move states without color', (
    WidgetTester tester,
  ) async {
    final Position position = FenCodec.decode(FenCodec.standardInitialPosition);
    final Square selected = Square.fromAlgebraic('e2');
    final List<Move> moves = const MoveGenerator().legalMoves(
      position,
      from: selected,
    );
    Square? tapped;

    await tester.pumpWidget(
      localizedTestApp(
        Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 480,
              child: ChessBoard(
                position: position,
                selectedSquare: selected,
                legalMoves: moves,
                lastMove: null,
                checkedKingSquare: null,
                flipped: false,
                onSquareTap: (Square square) => tapped = square,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp(r'White pawn on E2, selected square')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'E4, empty, legal move')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    expect(tapped, Square.fromAlgebraic('e4'));
  });
}
