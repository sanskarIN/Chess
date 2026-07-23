import 'package:flutter/foundation.dart';

import '../domain/board/square.dart';
import '../domain/model/chess_game.dart';
import '../domain/model/game_result.dart';
import '../domain/model/move.dart';
import '../domain/model/move_record.dart';
import '../domain/model/piece.dart';
import '../domain/model/piece_color.dart';
import '../domain/model/position.dart';
import '../domain/rules/move_generator.dart';
import 'game_setup.dart';

final class SquareSelectionResult {
  const SquareSelectionResult({
    this.playedMove,
    this.promotionChoices = const <Move>[],
  });

  final Move? playedMove;
  final List<Move> promotionChoices;

  bool get needsPromotionChoice => promotionChoices.isNotEmpty;
}

final class ChessGameController extends ChangeNotifier {
  ChessGameController({
    required this.setup,
    ChessGame? game,
    DateTime? startedAt,
  }) : _game = game ?? ChessGame(gameId: _createGameId()),
       _startedAt = startedAt ?? DateTime.now();

  static const MoveGenerator _moveGenerator = MoveGenerator();

  final GameSetup setup;
  DateTime _startedAt;
  ChessGame _game;
  Square? _selectedSquare;
  bool _boardFlipped = false;
  bool _resultAcknowledged = false;

  ChessGame get game => _game;
  Position get position => _game.position;
  GameResult? get result => _game.result;
  Square? get selectedSquare => _selectedSquare;
  bool get boardFlipped => _boardFlipped;
  bool get canUndo => _game.canUndo;
  bool get canRedo => _game.canRedo;
  bool get resultAcknowledged => _resultAcknowledged;
  DateTime get startedAt => _startedAt;

  Move? get lastMove {
    final List<MoveRecord> records = _game.moveRecords;
    return records.isEmpty ? null : records.last.move;
  }

  Square? get checkedKingSquare {
    if (!_moveGenerator.isInCheck(position, position.sideToMove)) {
      return null;
    }
    return position.kingSquare(position.sideToMove);
  }

  List<Move> get legalMovesForSelection {
    final Square? selected = _selectedSquare;
    if (selected == null) {
      return const <Move>[];
    }
    return _game.legalMoves
        .where((Move move) => move.from == selected)
        .toList(growable: false);
  }

  List<Piece> capturedBy(PieceColor capturingColor) {
    return _game.capturedPieces
        .where((Piece piece) => piece.color == capturingColor.opposite)
        .toList(growable: false);
  }

  SquareSelectionResult selectSquare(Square square) {
    if (result != null) {
      return const SquareSelectionResult();
    }

    final Piece? tappedPiece = position.pieceAt(square);
    final Square? selected = _selectedSquare;
    if (selected == null) {
      if (tappedPiece?.color == position.sideToMove) {
        _selectedSquare = square;
        notifyListeners();
      }
      return const SquareSelectionResult();
    }

    if (tappedPiece?.color == position.sideToMove) {
      _selectedSquare = square;
      notifyListeners();
      return const SquareSelectionResult();
    }

    final List<Move> matches = _game.legalMoves
        .where((Move move) => move.from == selected && move.to == square)
        .toList(growable: false);
    if (matches.isEmpty) {
      _selectedSquare = null;
      notifyListeners();
      return const SquareSelectionResult();
    }
    if (matches.length > 1) {
      return SquareSelectionResult(
        promotionChoices: List<Move>.unmodifiable(matches),
      );
    }

    playMove(matches.single);
    return SquareSelectionResult(playedMove: matches.single);
  }

  void playMove(Move move) {
    _game.play(move);
    _selectedSquare = null;
    _resultAcknowledged = false;
    if (setup.rotateAfterMove) {
      _boardFlipped = !_boardFlipped;
    }
    notifyListeners();
  }

  void undo() {
    if (!canUndo) {
      return;
    }
    _game.undo();
    _selectedSquare = null;
    _resultAcknowledged = false;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) {
      return;
    }
    _game.redo();
    _selectedSquare = null;
    _resultAcknowledged = false;
    notifyListeners();
  }

  void flipBoard() {
    _boardFlipped = !_boardFlipped;
    notifyListeners();
  }

  void offerAcceptedDraw() {
    if (result != null) {
      return;
    }
    _game.agreeDraw();
    _resultAcknowledged = false;
    notifyListeners();
  }

  void resignCurrentPlayer() {
    if (result != null) {
      return;
    }
    _game.resign(position.sideToMove);
    _resultAcknowledged = false;
    notifyListeners();
  }

  void acknowledgeResult() {
    _resultAcknowledged = true;
    notifyListeners();
  }

  void restart() {
    _game = ChessGame(gameId: _createGameId());
    _startedAt = DateTime.now();
    _selectedSquare = null;
    _resultAcknowledged = false;
    notifyListeners();
  }

  static String _createGameId() {
    return 'game-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }
}
