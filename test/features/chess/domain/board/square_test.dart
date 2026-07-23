import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Square', () {
    test('maps every index to canonical algebraic notation', () {
      expect(Square.values, hasLength(64));
      expect(Square.fromIndex(0).algebraic, 'a1');
      expect(Square.fromIndex(7).algebraic, 'h1');
      expect(Square.fromIndex(56).algebraic, 'a8');
      expect(Square.fromIndex(63).algebraic, 'h8');
      expect(Square.fromAlgebraic('e4').index, 28);
    });

    test('rejects malformed coordinates', () {
      expect(() => Square.fromAlgebraic('i4'), throwsFormatException);
      expect(() => Square.fromAlgebraic('a0'), throwsFormatException);
      expect(() => Square.fromAlgebraic('A1'), throwsFormatException);
      expect(() => Square.fromIndex(64), throwsRangeError);
    });

    test('offset never wraps across a board edge', () {
      final Square a1 = Square.fromAlgebraic('a1');
      final Square h8 = Square.fromAlgebraic('h8');

      expect(a1.offset(fileDelta: -1, rankDelta: 0), isNull);
      expect(a1.offset(fileDelta: 0, rankDelta: -1), isNull);
      expect(h8.offset(fileDelta: 1, rankDelta: 0), isNull);
      expect(a1.offset(fileDelta: 1, rankDelta: 2), Square.fromAlgebraic('b3'));
    });
  });
}
