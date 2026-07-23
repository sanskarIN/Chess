import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/sqflite_app_database.dart';
import '../data/challenge_repository.dart';
import '../data/deterministic_challenge_generator.dart';
import '../data/in_memory_challenge_repository.dart';
import '../data/local_hint_service.dart';
import '../data/sqflite_challenge_repository.dart';
import 'daily_challenges_controller.dart';

final Provider<ChallengeRepository> challengeRepositoryProvider =
    Provider<ChallengeRepository>((Ref ref) {
      final database = ref.watch(appDatabaseProvider);
      if (database is SqfliteAppDatabase) {
        return SqfliteChallengeRepository(database: database);
      }
      return InMemoryChallengeRepository();
    });

final ChangeNotifierProvider<DailyChallengesController>
dailyChallengesControllerProvider =
    ChangeNotifierProvider<DailyChallengesController>((Ref ref) {
      return DailyChallengesController(
        repository: ref.watch(challengeRepositoryProvider),
        generator: const DeterministicChallengeGenerator(),
        hintService: const LocalHintService(),
      );
    });
