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

  testWidgets('RTL navigation does not mirror logical chess coordinates', (
    WidgetTester tester,
  ) async {
    final Position position = FenCodec.decode(FenCodec.standardInitialPosition);

    await tester.pumpWidget(
      localizedTestApp(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 480,
                child: ChessBoard(
                  position: position,
                  selectedSquare: null,
                  legalMoves: const <Move>[],
                  lastMove: null,
                  checkedKingSquare: null,
                  flipped: false,
                  onSquareTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final Offset a8 = tester.getTopLeft(
      find.byKey(const ValueKey<String>('square-a8')),
    );
    final Offset h8 = tester.getTopLeft(
      find.byKey(const ValueKey<String>('square-h8')),
    );
    expect(a8.dx, lessThan(h8.dx));
    expect(a8.dy, h8.dy);
  });
}
