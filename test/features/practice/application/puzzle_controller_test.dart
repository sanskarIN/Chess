import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/reward_wallet.dart';
import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/practice/application/puzzle_controller.dart';
import 'package:chess_master/features/practice/data/asset_training_puzzle_repository.dart';
import 'package:chess_master/features/practice/data/in_memory_learning_progress_repository.dart';
import 'package:chess_master/features/practice/domain/training_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects a wrong move, solves a line, and rewards only once', () async {
    final TrainingPuzzle puzzle =
        (await const AssetTrainingPuzzleRepository().load()).first;
    final InMemoryLearningProgressRepository progress =
        InMemoryLearningProgressRepository();
    final InMemoryChallengeRepository rewards = InMemoryChallengeRepository();
    final PuzzleController controller = PuzzleController(
      puzzle: puzzle,
      progressRepository: progress,
      challengeRepository: rewards,
    );
    await controller.initialize();

    await controller.selectSquare(Square.fromAlgebraic('d8'));
    await controller.selectSquare(Square.fromAlgebraic('e7'));
    expect(controller.success, isFalse);
    expect(controller.progress!.attempts, 1);

    await controller.selectSquare(Square.fromAlgebraic('d8'));
    await controller.selectSquare(Square.fromAlgebraic('h4'));
    expect(controller.success, isTrue);
    expect(controller.newReward, isTrue);

    await controller.retry();
    await controller.selectSquare(Square.fromAlgebraic('d8'));
    await controller.selectSquare(Square.fromAlgebraic('h4'));
    expect(controller.newReward, isFalse);
    expect(
      (await rewards.readLedger()).where(
        (entry) => entry.type == RewardTransactionType.practiceReward,
      ),
      hasLength(1),
    );
  });

  test('automatically plays the opponent reply in a multi-ply line', () async {
    final TrainingPuzzle puzzle =
        (await const AssetTrainingPuzzleRepository().load()).singleWhere(
          (TrainingPuzzle value) => value.type == TrainingPuzzleType.mateInTwo,
        );
    final PuzzleController controller = PuzzleController(
      puzzle: puzzle,
      progressRepository: InMemoryLearningProgressRepository(),
      challengeRepository: InMemoryChallengeRepository(),
    );

    await controller.selectSquare(puzzle.solution.first.from);
    await controller.selectSquare(puzzle.solution.first.to);

    expect(controller.completedPlies, 2);
    expect(controller.lastMove, puzzle.solution[1]);
    expect(controller.success, isFalse);
  });
}
