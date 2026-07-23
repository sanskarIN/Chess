import 'package:flutter/foundation.dart';

import '../../challenges/data/challenge_repository.dart';
import '../../challenges/domain/reward_wallet.dart';
import '../../chess/domain/board/square.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/rules/move_generator.dart';
import '../domain/learning_progress.dart';
import '../domain/tutorial_lesson.dart';

final class TutorialLessonController extends ChangeNotifier {
  TutorialLessonController({
    required this.lesson,
    required this.progressRepository,
    required this.challengeRepository,
  }) : _game = ChessGame(
         gameId: 'tutorial-${lesson.id}',
         initialPosition: lesson.initialPosition,
       );

  static const MoveGenerator _generator = MoveGenerator();

  final TutorialLesson lesson;
  final LearningProgressRepository progressRepository;
  final ChallengeRepository challengeRepository;

  ChessGame _game;
  Square? _selectedSquare;
  TutorialLessonProgress? _progress;
  bool _busy = false;
  bool _success = false;
  bool _newReward = false;
  String? _errorCode;

  ChessGame get game => _game;
  Position get position => _game.position;
  Square? get selectedSquare => _selectedSquare;
  TutorialLessonProgress? get progress => _progress;
  bool get busy => _busy;
  bool get success => _success;
  bool get newReward => _newReward;
  String? get errorCode => _errorCode;
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
    final Map<String, TutorialLessonProgress> all = await progressRepository
        .loadTutorialProgress();
    _progress = all[lesson.id];
    notifyListeners();
  }

  Future<void> selectSquare(Square square) async {
    if (_busy || _success) {
      return;
    }
    if (lesson.expectedSquare != null) {
      if (square == lesson.expectedSquare) {
        await _complete();
      } else {
        await _recordIncorrectAttempt();
      }
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

    final List<Move> candidates = _game.legalMoves
        .where((Move move) => move.from == selected && move.to == square)
        .toList(growable: false);
    final Move expected = lesson.expectedMove!;
    final Move? chosen = candidates
        .where((Move move) => move == expected)
        .firstOrNull;
    if (chosen == null) {
      _selectedSquare = null;
      await _recordIncorrectAttempt();
      return;
    }
    _game.play(chosen);
    _selectedSquare = null;
    await _complete();
  }

  Future<void> retry() async {
    if (_busy) {
      return;
    }
    _game = ChessGame(
      gameId: 'tutorial-${lesson.id}-${DateTime.now().microsecondsSinceEpoch}',
      initialPosition: lesson.initialPosition,
    );
    _selectedSquare = null;
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
      _progress = await progressRepository.recordTutorialAttempt(lesson.id);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _complete() async {
    _busy = true;
    _errorCode = null;
    notifyListeners();
    final DateTime now = DateTime.now().toUtc();
    try {
      final TutorialLessonProgress completed = await progressRepository
          .completeTutorialLesson(lesson.id, now);
      final bool firstReward = completed.rewardClaimedAt == null;
      if (lesson.rewardCoins > 0) {
        await challengeRepository.grantEarnedReward(
          type: RewardTransactionType.tutorialReward,
          source: 'tutorial:${lesson.id}',
          coins: lesson.rewardCoins,
          hints: 0,
          now: now,
        );
        await progressRepository.markTutorialRewardClaimed(lesson.id, now);
      }
      _progress = TutorialLessonProgress(
        lessonId: completed.lessonId,
        attempts: completed.attempts,
        completedAt: completed.completedAt,
        rewardClaimedAt: lesson.rewardCoins > 0
            ? (completed.rewardClaimedAt ?? now)
            : completed.rewardClaimedAt,
      );
      _newReward = firstReward && lesson.rewardCoins > 0;
      _success = true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
