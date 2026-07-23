import 'package:chess_master/features/computer_player/data/uci/uci_message.dart';
import 'package:chess_master/features/computer_player/data/uci/uci_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const UciMessageParser parser = UciMessageParser();

  test('parses UCI handshake and identity messages', () {
    expect(parser.parse('uciok'), isA<UciInitialized>());
    expect(parser.parse('readyok'), isA<UciReady>());
    expect(
      parser.parse('id name Stockfish 18'),
      isA<UciIdentifier>()
          .having((UciIdentifier id) => id.field, 'field', 'name')
          .having((UciIdentifier id) => id.value, 'value', 'Stockfish 18'),
    );
  });

  test('parses analysis, principal variation, best move, and ponder', () {
    final UciInfo info =
        parser.parse(
              'info depth 12 score cp 34 nodes 4567 time 89 '
              'pv e2e4 e7e5 g1f3',
            )
            as UciInfo;
    final UciBestMove best =
        parser.parse('bestmove e2e4 ponder e7e5') as UciBestMove;

    expect(info.depth, 12);
    expect(info.scoreCentipawns, 34);
    expect(info.nodes, 4567);
    expect(info.elapsedMilliseconds, 89);
    expect(info.principalVariation.map((move) => move.uci), <String>[
      'e2e4',
      'e7e5',
      'g1f3',
    ]);
    expect(best.move.uci, 'e2e4');
    expect(best.ponder?.uci, 'e7e5');
  });

  test('rejects a missing best move', () {
    expect(
      () => parser.parse('bestmove (none)'),
      throwsA(isA<FormatException>()),
    );
  });
}
