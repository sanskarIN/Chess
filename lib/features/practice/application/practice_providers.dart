import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/sqflite_app_database.dart';
import '../data/asset_training_puzzle_repository.dart';
import '../data/in_memory_learning_progress_repository.dart';
import '../data/sqflite_learning_progress_repository.dart';
import '../domain/learning_progress.dart';
import '../domain/training_puzzle.dart';

final Provider<LearningProgressRepository> learningProgressRepositoryProvider =
    Provider<LearningProgressRepository>((Ref ref) {
      final database = ref.watch(appDatabaseProvider);
      if (database is SqfliteAppDatabase) {
        return SqfliteLearningProgressRepository(database: database);
      }
      return InMemoryLearningProgressRepository();
    });

final Provider<TrainingPuzzleRepository> trainingPuzzleRepositoryProvider =
    Provider<TrainingPuzzleRepository>((Ref ref) {
      return const AssetTrainingPuzzleRepository();
    });

final FutureProvider<List<TrainingPuzzle>> trainingPuzzlesProvider =
    FutureProvider<List<TrainingPuzzle>>((Ref ref) {
      return ref.watch(trainingPuzzleRepositoryProvider).load();
    });

final FutureProvider<Map<String, TutorialLessonProgress>>
tutorialProgressProvider = FutureProvider<Map<String, TutorialLessonProgress>>((
  Ref ref,
) {
  return ref.watch(learningProgressRepositoryProvider).loadTutorialProgress();
});

final FutureProvider<Map<String, PracticeExerciseProgress>>
practiceProgressProvider =
    FutureProvider<Map<String, PracticeExerciseProgress>>((Ref ref) {
      return ref
          .watch(learningProgressRepositoryProvider)
          .loadPracticeProgress();
    });
