import 'dart:io';

import '../lib/features/chess/domain/model/chess_game.dart';
import '../lib/features/chess/domain/model/game_result.dart';
import '../lib/features/chess/domain/model/move.dart';
import '../lib/features/chess/domain/model/piece_color.dart';
import '../lib/features/chess/domain/model/piece_type.dart';
import '../lib/features/chess/domain/notation/fen_codec.dart';
import '../lib/features/chess/domain/notation/pgn_codec.dart';
import '../lib/features/chess/domain/rules/move_generator.dart';
import '../lib/features/chess/domain/rules/perft.dart';

void main() {
  const Perft perft = Perft();
  final start = FenCodec.decode(FenCodec.standardInitialPosition);
  _expectEqual(perft.count(start, 1), 20, 'start perft depth 1');
  _expectEqual(perft.count(start, 2), 400, 'start perft depth 2');
  _expectEqual(perft.count(start, 3), 8902, 'start perft depth 3');
  _expectEqual(perft.count(start, 4), 197281, 'start perft depth 4');

  final kiwipete = FenCodec.decode(
    'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/'
    'PPPBBPPP/R3K2R w KQkq - 0 1',
  );
  _expectEqual(perft.count(kiwipete, 1), 48, 'Kiwipete depth 1');
  _expectEqual(perft.count(kiwipete, 2), 2039, 'Kiwipete depth 2');
  _expectEqual(perft.count(kiwipete, 3), 97862, 'Kiwipete depth 3');

  final rookEndgame = FenCodec.decode(
    '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
  );
  _expectEqual(perft.count(rookEndgame, 1), 14, 'endgame depth 1');
  _expectEqual(perft.count(rookEndgame, 2), 191, 'endgame depth 2');
  _expectEqual(perft.count(rookEndgame, 3), 2812, 'endgame depth 3');
  _expectEqual(perft.count(rookEndgame, 4), 43238, 'endgame depth 4');

  const MoveGenerator generator = MoveGenerator();
  final enPassantPin = FenCodec.decode('k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');
  _expectEqual(
    generator.isLegal(enPassantPin, Move.fromUci('e5d6')),
    false,
    'pinned en passant',
  );

  final castling = FenCodec.decode('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
  _expectEqual(
    generator.legalMoves(castling).contains(Move.fromUci('e1g1')),
    true,
    'white king-side castling',
  );
  _expectEqual(
    generator.legalMoves(castling).contains(Move.fromUci('e1c1')),
    true,
    'white queen-side castling',
  );

  final enPassant = FenCodec.decode('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2');
  final enPassantAfter = enPassant.applyUnchecked(Move.fromUci('e5d6'));
  _expectEqual(
    FenCodec.encode(enPassantAfter),
    '4k3/8/3P4/8/8/8/8/4K3 b - - 0 2',
    'en passant transition',
  );

  final promotion = FenCodec.decode('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
  final promotionChoices = generator
      .legalMoves(promotion)
      .where((move) => move.promotion != null)
      .map((move) => move.promotion)
      .toSet();
  _expectEqual(promotionChoices.length, 4, 'promotion choice count');
  for (final PieceType choice in const <PieceType>[
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
  ]) {
    _expectEqual(
      promotionChoices.contains(choice),
      true,
      'promotion choice ${choice.name}',
    );
  }

  final repetition = ChessGame(gameId: 'verify-repetition');
  for (final String uci in <String>[
    'g1f3',
    'g8f6',
    'f3g1',
    'f6g8',
    'g1f3',
    'g8f6',
    'f3g1',
    'f6g8',
  ]) {
    repetition.play(Move.fromUci(uci));
  }
  _expectEqual(
    repetition.result,
    const GameResult.draw(GameResultReason.threefoldRepetition),
    'threefold repetition',
  );

  final fiftyMove = ChessGame(
    gameId: 'verify-fifty',
    initialPosition: FenCodec.decode('4k2r/8/8/8/8/8/8/R3K3 w - - 99 1'),
  )..play(Move.fromUci('a1a2'));
  _expectEqual(
    fiftyMove.result,
    const GameResult.draw(GameResultReason.fiftyMoveRule),
    'fifty-move rule',
  );

  final stalemate = ChessGame(
    gameId: 'verify-stalemate',
    initialPosition: FenCodec.decode('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
  );
  _expectEqual(
    stalemate.result,
    const GameResult.draw(GameResultReason.stalemate),
    'stalemate',
  );

  final insufficient = ChessGame(
    gameId: 'verify-material',
    initialPosition: FenCodec.decode('4k3/8/8/8/8/8/8/2B1K3 w - - 0 1'),
  );
  _expectEqual(
    insufficient.result,
    const GameResult.draw(GameResultReason.insufficientMaterial),
    'insufficient material',
  );

  final mate = ChessGame(gameId: 'verify-pgn');
  for (final String uci in <String>['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
    mate.play(Move.fromUci(uci));
  }
  const PgnCodec pgnCodec = PgnCodec();
  final String pgn = pgnCodec.encode(mate);
  final imported = pgnCodec.decode(pgn, gameId: 'verify-import');
  _expectEqual(
    imported.game.result,
    const GameResult.blackWin(GameResultReason.checkmate),
    'PGN checkmate round trip',
  );

  final timeout = ChessGame(
    gameId: 'verify-timeout',
    initialPosition: FenCodec.decode('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'),
  )..declareTimeout(PieceColor.white);
  _expectEqual(
    timeout.result,
    const GameResult.draw(GameResultReason.timeout),
    'timeout without mating material',
  );

  stdout.writeln('Chess domain verification passed.');
}

void _expectEqual(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    throw StateError('$label: expected $expected, received $actual');
  }
}
