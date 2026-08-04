import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../domain/match_history.dart';

abstract interface class MatchHistoryRepository {
  Future<bool> recordCompletedMatch({
    required GameSetup setup,
    required ChessGame game,
    required DateTime startedAt,
    required DateTime completedAt,
    required int hintCount,
  });

  Future<List<MatchHistoryEntry>> loadHistory({
    MatchHistoryFilter filter = MatchHistoryFilter.all,
  });

  Future<ChessStatistics> loadStatistics({DateTime? now});

  Future<List<AchievementProgress>> loadAchievements({DateTime? now});

  Future<void> resetStatistics(DateTime now);
}
