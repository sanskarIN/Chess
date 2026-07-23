import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/chess/domain/rules/perft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Perft perft = Perft();

  group('perft', () {
    test('matches the standard initial-position reference counts', () {
      final position = FenCodec.decode(FenCodec.standardInitialPosition);

      expect(perft.count(position, 1), 20);
      expect(perft.count(position, 2), 400);
      expect(perft.count(position, 3), 8902);
      expect(perft.count(position, 4), 197281);
    });

    test('matches the Kiwipete castling and pin reference counts', () {
      final position = FenCodec.decode(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/'
        'PPPBBPPP/R3K2R w KQkq - 0 1',
      );

      expect(perft.count(position, 1), 48);
      expect(perft.count(position, 2), 2039);
      expect(perft.count(position, 3), 97862);
    });

    test('matches a rook and en-passant endgame reference position', () {
      final position = FenCodec.decode(
        '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
      );

      expect(perft.count(position, 1), 14);
      expect(perft.count(position, 2), 191);
      expect(perft.count(position, 3), 2812);
      expect(perft.count(position, 4), 43238);
    });
  });
}
