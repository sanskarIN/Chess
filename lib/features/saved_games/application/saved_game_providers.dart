import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/sqflite_app_database.dart';
import '../data/in_memory_saved_game_repository.dart';
import '../data/saved_game_repository.dart';
import '../data/sqflite_saved_game_repository.dart';
import '../domain/saved_game.dart';

final Provider<SavedGameRepository> savedGameRepositoryProvider =
    Provider<SavedGameRepository>((Ref ref) {
      final database = ref.watch(appDatabaseProvider);
      if (database is SqfliteAppDatabase) {
        return SqfliteSavedGameRepository(database: database);
      }
      return InMemorySavedGameRepository();
    });

final FutureProvider<List<SavedGame>> savedGamesProvider =
    FutureProvider<List<SavedGame>>((Ref ref) {
      return ref.watch(savedGameRepositoryProvider).loadAll();
    });
