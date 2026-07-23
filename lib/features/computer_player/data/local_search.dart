import '../../chess/domain/board/square.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/piece.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../chess/domain/model/piece_type.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/domain/rules/move_generator.dart';
import '../domain/engine_difficulty.dart';

Map<String, Object?> searchPosition({
  required String fen,
  required int maximumDepth,
  required Duration budget,
  required EngineDifficulty difficulty,
}) {
  const MoveGenerator generator = MoveGenerator();
  final Position root = FenCodec.decode(fen);
  final List<Move> legalMoves = generator.legalMoves(root);
  if (legalMoves.isEmpty) {
    throw StateError('The supplied position has no legal move.');
  }

  final Stopwatch stopwatch = Stopwatch()..start();
  final _SearchCounter counter = _SearchCounter();
  Move bestMove = legalMoves.first;
  int bestScore = -_infinity;
  int completedDepth = 0;
  List<Move> bestLine = <Move>[bestMove];

  for (int depth = 1; depth <= maximumDepth; depth++) {
    if (_expired(stopwatch, budget)) {
      break;
    }
    final List<_ScoredMove> scored = <_ScoredMove>[];
    for (final Move move in _orderedMoves(root, legalMoves)) {
      if (_expired(stopwatch, budget)) {
        break;
      }
      final _NodeResult result = _negamax(
        root.applyUnchecked(move),
        depth - 1,
        -_infinity,
        _infinity,
        stopwatch,
        budget,
        generator,
        counter,
      );
      scored.add(
        _ScoredMove(
          move: move,
          score: -result.score,
          line: <Move>[move, ...result.line],
        ),
      );
    }
    if (scored.isEmpty) {
      break;
    }
    scored.sort(
      (_ScoredMove first, _ScoredMove second) =>
          second.score.compareTo(first.score),
    );
    final int choiceIndex =
        difficulty == EngineDifficulty.beginner &&
            scored.length > 1 &&
            root.fullmoveNumber % 3 == 0
        ? 1
        : 0;
    bestMove = scored[choiceIndex].move;
    bestScore = scored[choiceIndex].score;
    bestLine = scored[choiceIndex].line;
    completedDepth = depth;
  }
  stopwatch.stop();

  return <String, Object?>{
    'bestMove': bestMove.uci,
    'depth': completedDepth == 0 ? 1 : completedDepth,
    'nodes': counter.nodes,
    'elapsedMillis': stopwatch.elapsedMilliseconds,
    'score': bestScore == -_infinity ? 0 : bestScore,
    'pv': bestLine.map((Move move) => move.uci).toList(growable: false),
  };
}

const int _infinity = 1000000;

_NodeResult _negamax(
  Position position,
  int depth,
  int alpha,
  int beta,
  Stopwatch stopwatch,
  Duration budget,
  MoveGenerator generator,
  _SearchCounter counter,
) {
  counter.nodes++;
  if (depth <= 0 || _expired(stopwatch, budget)) {
    return _NodeResult(score: _evaluate(position), line: const <Move>[]);
  }
  final List<Move> moves = generator.legalMoves(position);
  if (moves.isEmpty) {
    if (generator.isInCheck(position, position.sideToMove)) {
      return _NodeResult(score: -100000 + depth, line: const <Move>[]);
    }
    return const _NodeResult(score: 0, line: <Move>[]);
  }

  int bestScore = -_infinity;
  List<Move> bestLine = const <Move>[];
  int currentAlpha = alpha;
  for (final Move move in _orderedMoves(position, moves)) {
    if (_expired(stopwatch, budget)) {
      break;
    }
    final _NodeResult child = _negamax(
      position.applyUnchecked(move),
      depth - 1,
      -beta,
      -currentAlpha,
      stopwatch,
      budget,
      generator,
      counter,
    );
    final int score = -child.score;
    if (score > bestScore) {
      bestScore = score;
      bestLine = <Move>[move, ...child.line];
    }
    if (score > currentAlpha) {
      currentAlpha = score;
    }
    if (currentAlpha >= beta) {
      break;
    }
  }
  if (bestScore == -_infinity) {
    return _NodeResult(score: _evaluate(position), line: const <Move>[]);
  }
  return _NodeResult(score: bestScore, line: bestLine);
}

List<Move> _orderedMoves(Position position, List<Move> moves) {
  final List<Move> ordered = List<Move>.of(moves);
  ordered.sort((Move first, Move second) {
    return _movePriority(
      position,
      second,
    ).compareTo(_movePriority(position, first));
  });
  return ordered;
}

int _movePriority(Position position, Move move) {
  final Piece? captured = position.capturedPiece(move);
  final int captureValue = captured == null ? 0 : _pieceValue(captured.type);
  final int promotionValue = move.promotion == null
      ? 0
      : _pieceValue(move.promotion!);
  return (captureValue * 10) + promotionValue;
}

int _evaluate(Position position) {
  int white = 0;
  int black = 0;
  for (final MapEntry<Square, Piece> entry in position.pieces()) {
    final int value = _pieceValue(entry.value.type);
    if (entry.value.color == PieceColor.white) {
      white += value;
    } else {
      black += value;
    }
  }
  final int whitePerspective = white - black;
  return position.sideToMove == PieceColor.white
      ? whitePerspective
      : -whitePerspective;
}

int _pieceValue(PieceType type) {
  return switch (type) {
    PieceType.pawn => 100,
    PieceType.knight => 320,
    PieceType.bishop => 330,
    PieceType.rook => 500,
    PieceType.queen => 900,
    PieceType.king => 20000,
  };
}

bool _expired(Stopwatch stopwatch, Duration budget) {
  return stopwatch.elapsed >= budget;
}

final class _SearchCounter {
  int nodes = 0;
}

final class _NodeResult {
  const _NodeResult({required this.score, required this.line});

  final int score;
  final List<Move> line;
}

final class _ScoredMove {
  const _ScoredMove({
    required this.move,
    required this.score,
    required this.line,
  });

  final Move move;
  final int score;
  final List<Move> line;
}
