import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/chess/domain/notation/san_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SanCodec codec = SanCodec();

  group('SanCodec', () {
    test('encodes and decodes a checkmating sequence', () {
      final ChessGame game = ChessGame(gameId: 'fools-mate');
      final List<(String, String)> moves = <(String, String)>[
        ('f2f3', 'f3'),
        ('e7e5', 'e5'),
        ('g2g4', 'g4'),
        ('d8h4', 'Qh4#'),
      ];

      for (final (String, String) expected in moves) {
        final Move move = Move.fromUci(expected.$1);
        expect(codec.encode(game.position, move), expected.$2);
        expect(codec.decode(game.position, expected.$2), move);
        game.play(move);
      }
    });

    test('encodes castling and promotion', () {
      final castlePosition = FenCodec.decode(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      );
      final promotionPosition = FenCodec.decode(
        '7k/P7/8/8/8/8/8/4K3 w - - 0 1',
      );

      expect(codec.encode(castlePosition, Move.fromUci('e1g1')), 'O-O');
      expect(codec.decode(castlePosition, '0-0'), Move.fromUci('e1g1'));
      expect(codec.encode(promotionPosition, Move.fromUci('a7a8q')), 'a8=Q+');
    });

    test('disambiguates pieces by file and rank', () {
      final knightPosition = FenCodec.decode(
        '4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1',
      );
      final rookPosition = FenCodec.decode('4k3/8/8/8/8/R7/8/R3K3 w - - 0 1');

      expect(codec.encode(knightPosition, Move.fromUci('b1d2')), 'Nbd2');
      expect(codec.encode(knightPosition, Move.fromUci('f1d2')), 'Nfd2');
      expect(codec.encode(rookPosition, Move.fromUci('a1a2')), 'R1a2');
      expect(codec.encode(rookPosition, Move.fromUci('a3a2')), 'R3a2');
    });

    test('rejects illegal and ambiguous text', () {
      final position = FenCodec.decode(FenCodec.standardInitialPosition);

      expect(() => codec.decode(position, 'e5'), throwsFormatException);
      expect(
        () => codec.encode(position, Move.fromUci('e2e5')),
        throwsStateError,
      );
    });
  });
}
