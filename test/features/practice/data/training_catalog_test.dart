import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/practice/data/asset_training_puzzle_repository.dart';
import 'package:chess_master/features/practice/data/tutorial_catalog.dart';
import 'package:chess_master/features/practice/domain/training_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every bundled puzzle and verifies every solution move', () async {
    final List<TrainingPuzzle> puzzles =
        await const AssetTrainingPuzzleRepository().load();

    expect(puzzles, hasLength(5));
    expect(
      puzzles.map((TrainingPuzzle puzzle) => puzzle.id).toSet(),
      hasLength(5),
    );
    for (final TrainingPuzzle puzzle in puzzles) {
      final ChessGame game = ChessGame(
        gameId: 'test-${puzzle.id}',
        initialPosition: puzzle.initialPosition,
      );
      for (final move in puzzle.solution) {
        expect(game.legalMoves, contains(move), reason: puzzle.id);
        game.play(move);
      }
    }
  });

  test('contains all seventeen legal tutorial lessons', () {
    expect(TutorialCatalog.lessons, hasLength(17));
    expect(
      TutorialCatalog.lessons.map((lesson) => lesson.id).toSet(),
      hasLength(17),
    );
    for (final lesson in TutorialCatalog.lessons) {
      final expectedMove = lesson.expectedMove;
      if (expectedMove == null) {
        expect(lesson.expectedSquare, isNotNull);
        continue;
      }
      final ChessGame game = ChessGame(
        gameId: 'lesson-${lesson.id}',
        initialPosition: lesson.initialPosition,
      );
      expect(game.legalMoves, contains(expectedMove), reason: lesson.id);
      game.play(expectedMove);
    }
  });
}
