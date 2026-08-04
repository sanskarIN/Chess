import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/sqflite_app_database.dart';
import '../data/in_memory_match_history_repository.dart';
import '../data/match_history_repository.dart';
import '../data/sqflite_match_history_repository.dart';
import '../domain/match_history.dart';

final Provider<MatchHistoryRepository> matchHistoryRepositoryProvider =
    Provider<MatchHistoryRepository>((Ref ref) {
      final database = ref.watch(appDatabaseProvider);
      if (database is SqfliteAppDatabase) {
        return SqfliteMatchHistoryRepository(database: database);
      }
      return InMemoryMatchHistoryRepository();
    });

final NotifierProvider<MatchHistoryFilterController, MatchHistoryFilter>
matchHistoryFilterProvider =
    NotifierProvider<MatchHistoryFilterController, MatchHistoryFilter>(
      MatchHistoryFilterController.new,
    );

final class MatchHistoryFilterController extends Notifier<MatchHistoryFilter> {
  @override
  MatchHistoryFilter build() => MatchHistoryFilter.all;

  void select(MatchHistoryFilter filter) {
    state = filter;
  }
}

final FutureProvider<List<MatchHistoryEntry>> matchHistoryProvider =
    FutureProvider<List<MatchHistoryEntry>>((Ref ref) {
      final MatchHistoryFilter filter = ref.watch(matchHistoryFilterProvider);
      return ref
          .watch(matchHistoryRepositoryProvider)
          .loadHistory(filter: filter);
    });

final FutureProvider<ChessStatistics> chessStatisticsProvider =
    FutureProvider<ChessStatistics>((Ref ref) {
      return ref.watch(matchHistoryRepositoryProvider).loadStatistics();
    });

final FutureProvider<List<AchievementProgress>> achievementsProvider =
    FutureProvider<List<AchievementProgress>>((Ref ref) {
      return ref.watch(matchHistoryRepositoryProvider).loadAchievements();
    });
