import 'package:flutter/foundation.dart';

import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/reward_wallet.dart';
import '../../chess/domain/board/square.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/rules/move_generator.dart';
import '../domain/learning_progress.dart';
import '../domain/training_puzzle.dart';

final class PuzzleController extends ChangeNotifier {
  PuzzleController({
    required this.puzzle,
    required this.progressRepository,
    required this.challengeRepository,
  }) : _game = ChessGame(
         gameId: 'practice-${puzzle.id}',
         initialPosition: puzzle.initialPosition,
       );

  static const MoveGenerator _generator = MoveGenerator();

  final TrainingPuzzle puzzle;
  final LearningProgressRepository progressRepository;
  final ChallengeRepository challengeRepository;

  ChessGame _game;
  Square? _selectedSquare;
  PracticeExerciseProgress? _progress;
  int _solutionIndex = 0;
  bool _busy = false;
  bool _success = false;
  bool _newReward = false;
  String? _errorCode;

  ChessGame get game => _game;
  Position get position => _game.position;
  Square? get selectedSquare => _selectedSquare;
  PracticeExerciseProgress? get progress => _progress;
  bool get busy => _busy;
  bool get success => _success;
  bool get newReward => _newReward;
  String? get errorCode => _errorCode;
  int get completedPlies => _solutionIndex;
  Move? get lastMove =>
      _game.moveRecords.isEmpty ? null : _game.moveRecords.last.move;

  Square? get checkedKingSquare {
    if (!_generator.isInCheck(position, position.sideToMove)) {
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

  Future<void> initialize() async {
    final Map<String, PracticeExerciseProgress> all = await progressRepository
        .loadPracticeProgress();
    _progress = all[puzzle.id];
    notifyListeners();
  }

  Future<void> selectSquare(Square square) async {
    if (_busy || _success) {
      return;
    }
    final Square? selected = _selectedSquare;
    if (selected == null) {
      if (position.pieceAt(square)?.color == position.sideToMove) {
        _selectedSquare = square;
        _errorCode = null;
        notifyListeners();
      }
      return;
    }
    if (position.pieceAt(square)?.color == position.sideToMove) {
      _selectedSquare = square;
      _errorCode = null;
      notifyListeners();
      return;
    }
    final Move expected = puzzle.solution[_solutionIndex];
    final Move? chosen = _game.legalMoves
        .where(
          (Move move) =>
              move.from == selected && move.to == square && move == expected,
        )
        .firstOrNull;
    if (chosen == null) {
      _selectedSquare = null;
      await _recordIncorrectAttempt();
      return;
    }

    _game.play(chosen);
    _solutionIndex++;
    _selectedSquare = null;
    _errorCode = null;
    notifyListeners();

    if (_solutionIndex < puzzle.solution.length) {
      _game.play(puzzle.solution[_solutionIndex]);
      _solutionIndex++;
      notifyListeners();
    }
    if (_solutionIndex >= puzzle.solution.length) {
      await _complete();
    }
  }

  Future<void> retry() async {
    if (_busy) {
      return;
    }
    _game = ChessGame(
      gameId: 'practice-${puzzle.id}-${DateTime.now().microsecondsSinceEpoch}',
      initialPosition: puzzle.initialPosition,
    );
    _selectedSquare = null;
    _solutionIndex = 0;
    _success = false;
    _newReward = false;
    _errorCode = null;
    notifyListeners();
  }

  Future<void> _recordIncorrectAttempt() async {
    _busy = true;
    _errorCode = 'try_again';
    notifyListeners();
    try {
      _progress = await progressRepository.recordPracticeAttempt(
        exerciseId: puzzle.id,
        exerciseType: puzzle.type.name,
        now: DateTime.now().toUtc(),
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _complete() async {
    _busy = true;
    notifyListeners();
    final DateTime now = DateTime.now().toUtc();
    try {
      final bool firstReward = _progress?.isSolved != true;
      _progress = await progressRepository.completePracticeExercise(
        exerciseId: puzzle.id,
        exerciseType: puzzle.type.name,
        moveCount: puzzle.solution.length,
        now: now,
      );
      await challengeRepository.grantEarnedReward(
        type: RewardTransactionType.practiceReward,
        source: 'practice:${puzzle.id}',
        coins: 10,
        hints: 0,
        now: now,
      );
      _newReward = firstReward;
      _success = true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
