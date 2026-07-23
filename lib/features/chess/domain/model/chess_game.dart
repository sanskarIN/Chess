import '../notation/fen_codec.dart';
import '../notation/san_codec.dart';
import '../rules/move_generator.dart';
import '../rules/position_rules.dart';
import '../rules/repetition.dart';
import 'game_result.dart';
import 'move.dart';
import 'move_record.dart';
import 'piece.dart';
import 'piece_color.dart';
import 'position.dart';

final class ChessGame {
  ChessGame({
    required this.gameId,
    Position? initialPosition,
    MoveGenerator generator = const MoveGenerator(),
  }) : _generator = generator,
       _sanCodec = SanCodec(generator: generator),
       _initialPosition =
           initialPosition ??
           FenCodec.decode(FenCodec.standardInitialPosition) {
    if (gameId.trim().isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'Must not be empty.');
    }
    _positions.add(_initialPosition);
  }

  factory ChessGame.restore({
    required String gameId,
    required Position initialPosition,
    required Iterable<Move> moves,
    String? declaredResult,
    MoveGenerator generator = const MoveGenerator(),
  }) {
    final ChessGame game = ChessGame(
      gameId: gameId,
      initialPosition: initialPosition,
      generator: generator,
    );
    for (final Move move in moves) {
      game.play(move);
    }
    if (declaredResult != null) {
      game.declareImportedResult(declaredResult);
    }
    return game;
  }

  final String gameId;
  final Position _initialPosition;
  final MoveGenerator _generator;
  final SanCodec _sanCodec;
  final List<Position> _positions = <Position>[];
  final List<MoveRecord> _records = <MoveRecord>[];
  int _cursor = 0;
  GameResult? _declaredResult;

  Position get initialPosition => _initialPosition;
  Position get position => _positions[_cursor];
  int get ply => _cursor;
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _records.length;

  List<MoveRecord> get moveRecords {
    return List<MoveRecord>.unmodifiable(_records.take(_cursor));
  }

  List<Position> get positionHistory {
    return List<Position>.unmodifiable(_positions.take(_cursor + 1));
  }

  List<Piece> get capturedPieces {
    return List<Piece>.unmodifiable(
      moveRecords
          .map((MoveRecord record) => record.capturedPiece)
          .whereType<Piece>(),
    );
  }

  List<Move> get legalMoves => _generator.legalMoves(position);

  GameResult? get result => _declaredResult ?? _automaticResult();

  MoveRecord play(Move move) {
    if (result != null) {
      throw StateError('The game has already ended.');
    }
    if (!_generator.isLegal(position, move)) {
      throw StateError('Illegal move: ${move.uci}');
    }

    if (_cursor < _records.length) {
      _records.removeRange(_cursor, _records.length);
      _positions.removeRange(_cursor + 1, _positions.length);
    }

    final Position before = position;
    final Piece? capturedPiece = before.capturedPiece(move);
    final String san = _sanCodec.encode(before, move);
    final Position after = before.applyUnchecked(move);
    final int nextPly = _cursor + 1;
    final MoveRecord record = MoveRecord(
      id: '$gameId:$nextPly',
      ply: nextPly,
      move: move,
      san: san,
      positionBefore: before,
      positionAfter: after,
      capturedPiece: capturedPiece,
    );
    _records.add(record);
    _positions.add(after);
    _cursor = nextPly;
    _declaredResult = null;
    return record;
  }

  MoveRecord playSan(String san) => play(_sanCodec.decode(position, san));

  MoveRecord undo() {
    if (!canUndo) {
      throw StateError('No move is available to undo.');
    }
    _declaredResult = null;
    _cursor--;
    return _records[_cursor];
  }

  MoveRecord redo() {
    if (!canRedo) {
      throw StateError('No move is available to redo.');
    }
    final MoveRecord record = _records[_cursor];
    _cursor++;
    _declaredResult = null;
    return record;
  }

  void resign(PieceColor resigningColor) {
    _ensureActive();
    _declaredResult = resigningColor == PieceColor.white
        ? const GameResult.blackWin(GameResultReason.resignation)
        : const GameResult.whiteWin(GameResultReason.resignation);
  }

  void agreeDraw() {
    _ensureActive();
    _declaredResult = const GameResult.draw(GameResultReason.drawAgreement);
  }

  void declareTimeout(PieceColor timedOutColor) {
    _ensureActive();
    final PieceColor potentialWinner = timedOutColor.opposite;
    if (!PositionRules.canPossiblyMate(position, potentialWinner)) {
      _declaredResult = const GameResult.draw(GameResultReason.timeout);
      return;
    }
    _declaredResult = potentialWinner == PieceColor.black
        ? const GameResult.blackWin(GameResultReason.timeout)
        : const GameResult.whiteWin(GameResultReason.timeout);
  }

  void declareImportedResult(String notation) {
    final GameResult? automatic = _automaticResult();
    if (notation == '*') {
      if (automatic != null) {
        throw FormatException(
          'PGN declares an unfinished game but the position is terminal.',
        );
      }
      return;
    }
    final GameResult imported = switch (notation) {
      '1-0' => const GameResult.whiteWin(GameResultReason.adjudication),
      '0-1' => const GameResult.blackWin(GameResultReason.adjudication),
      '1/2-1/2' => const GameResult.draw(GameResultReason.adjudication),
      _ => throw FormatException('Invalid PGN result: $notation'),
    };
    if (automatic != null && automatic.notation != imported.notation) {
      throw FormatException(
        'PGN result $notation conflicts with ${automatic.notation}.',
      );
    }
    _declaredResult = automatic ?? imported;
  }

  int repetitionCount(Position target) {
    final String targetKey = Repetition.key(target, generator: _generator);
    return positionHistory
        .map(
          (Position historical) =>
              Repetition.key(historical, generator: _generator),
        )
        .where((String key) => key == targetKey)
        .length;
  }

  GameResult? _automaticResult() {
    final bool hasMove = _generator.hasAnyLegalMove(position);
    if (!hasMove) {
      if (_generator.isInCheck(position, position.sideToMove)) {
        return position.sideToMove == PieceColor.white
            ? const GameResult.blackWin(GameResultReason.checkmate)
            : const GameResult.whiteWin(GameResultReason.checkmate);
      }
      return const GameResult.draw(GameResultReason.stalemate);
    }
    if (position.halfmoveClock >= 100) {
      return const GameResult.draw(GameResultReason.fiftyMoveRule);
    }
    if (repetitionCount(position) >= 3) {
      return const GameResult.draw(GameResultReason.threefoldRepetition);
    }
    if (PositionRules.hasInsufficientMaterial(position)) {
      return const GameResult.draw(GameResultReason.insufficientMaterial);
    }
    return null;
  }

  void _ensureActive() {
    if (result != null) {
      throw StateError('The game has already ended.');
    }
  }
}
