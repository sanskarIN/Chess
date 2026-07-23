import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/reward_wallet.dart';
import 'package:chess_master/features/chess/domain/board/square.dart';
import 'package:chess_master/features/practice/application/tutorial_lesson_controller.dart';
import 'package:chess_master/features/practice/data/in_memory_learning_progress_repository.dart';
import 'package:chess_master/features/practice/data/tutorial_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'validates the requested move and grants its reward only once',
    () async {
      final InMemoryLearningProgressRepository progress =
          InMemoryLearningProgressRepository();
      final InMemoryChallengeRepository rewards = InMemoryChallengeRepository();
      final lesson = TutorialCatalog.lessons.singleWhere(
        (value) => value.id == 'pawn-movement',
      );
      final TutorialLessonController controller = TutorialLessonController(
        lesson: lesson,
        progressRepository: progress,
        challengeRepository: rewards,
      );
      await controller.initialize();

      await controller.selectSquare(Square.fromAlgebraic('e2'));
      await controller.selectSquare(Square.fromAlgebraic('e3'));
      expect(controller.success, isFalse);
      expect(controller.progress!.attempts, 1);

      await controller.selectSquare(Square.fromAlgebraic('e2'));
      await controller.selectSquare(Square.fromAlgebraic('e4'));
      expect(controller.success, isTrue);
      expect(controller.newReward, isTrue);

      await controller.retry();
      await controller.selectSquare(Square.fromAlgebraic('e2'));
      await controller.selectSquare(Square.fromAlgebraic('e4'));
      expect(controller.success, isTrue);
      expect(controller.newReward, isFalse);
      expect(
        (await rewards.readLedger()).where(
          (entry) => entry.type == RewardTransactionType.tutorialReward,
        ),
        hasLength(1),
      );
    },
  );

  test('coordinate lesson records incorrect taps and accepts e4', () async {
    final lesson = TutorialCatalog.lessons.first;
    final TutorialLessonController controller = TutorialLessonController(
      lesson: lesson,
      progressRepository: InMemoryLearningProgressRepository(),
      challengeRepository: InMemoryChallengeRepository(),
    );

    await controller.selectSquare(Square.fromAlgebraic('e3'));
    expect(controller.errorCode, 'try_again');
    await controller.selectSquare(Square.fromAlgebraic('e4'));
    expect(controller.success, isTrue);
  });
}
