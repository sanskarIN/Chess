import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/game_result.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/notation/pgn_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PgnCodec codec = PgnCodec();

  test('exports and imports a complete checkmating game', () {
    final ChessGame source = ChessGame(gameId: 'source');
    for (final String move in <String>['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      source.play(Move.fromUci(move));
    }

    final String pgn = codec.encode(
      source,
      tags: const <String, String>{
        'Event': 'Rules test',
        'White': 'Player 1',
        'Black': 'Player 2',
      },
    );
    final PgnDocument imported = codec.decode(pgn, gameId: 'imported');

    expect(pgn, contains('[Result "0-1"]'));
    expect(pgn, contains('1. f3 e5 2. g4 Qh4# 0-1'));
    expect(imported.game.moveRecords.map((record) => record.move.uci), <String>[
      'f2f3',
      'e7e5',
      'g2g4',
      'd8h4',
    ]);
    expect(
      imported.game.result,
      const GameResult.blackWin(GameResultReason.checkmate),
    );
  });

  test('ignores comments, NAGs, and side variations while importing', () {
    const String pgn = '''
[Event "Import test"]
[Result "*"]

1. e4 {King pawn} e5 \$1 2. Nf3 (2. Bc4 Nc6) Nc6 *
''';

    final PgnDocument imported = codec.decode(pgn, gameId: 'comments');

    expect(imported.game.moveRecords.map((record) => record.san), <String>[
      'e4',
      'e5',
      'Nf3',
      'Nc6',
    ]);
    expect(imported.game.result, isNull);
  });

  test('rejects conflicting or malformed results', () {
    const String conflicting = '''
[Result "1-0"]

1. f3 e5 2. g4 Qh4# 1-0
''';
    const String duplicateTag = '''
[Event "One"]
[Event "Two"]

*
''';

    expect(
      () => codec.decode(conflicting, gameId: 'conflict'),
      throwsFormatException,
    );
    expect(
      () => codec.decode(duplicateTag, gameId: 'duplicate'),
      throwsFormatException,
    );
  });
}
