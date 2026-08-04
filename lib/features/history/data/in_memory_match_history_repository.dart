import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/piece_color.dart';
import '../domain/achievement_catalog.dart';
import '../domain/match_history.dart';
import 'match_history_repository.dart';

final class InMemoryMatchHistoryRepository implements MatchHistoryRepository {
  final Map<String, MatchHistoryEntry> _entries = <String, MatchHistoryEntry>{};
  final Map<AchievementId, DateTime> _unlockedAt = <AchievementId, DateTime>{};
  DateTime? _resetAt;

  @override
  Future<bool> recordCompletedMatch({
    required GameSetup setup,
    required ChessGame game,
    required DateTime startedAt,
    required DateTime completedAt,
    required int hintCount,
  }) async {
    if (game.result == null || hintCount < 0) {
      return false;
    }
    final String id = 'history-${game.gameId}';
    if (_entries.containsKey(id)) {
      return false;
    }
    final PieceColor perspective = setup.humanColor ?? PieceColor.white;
    final PieceColor? winner = game.result!.winner;
    final MatchOutcome outcome = winner == null
        ? MatchOutcome.draw
        : winner == perspective
        ? MatchOutcome.win
        : MatchOutcome.loss;
    _entries[id] = MatchHistoryEntry(
      id: id,
      mode: setup.mode,
      opponentName: perspective == PieceColor.white
          ? setup.blackPlayerName
          : setup.whitePlayerName,
      playerColor: perspective,
      outcome: outcome,
      resultReason: game.result!.reason.name,
      completedAt: completedAt.toUtc(),
      duration: _safeDuration(startedAt, completedAt),
      moveCount: game.moveRecords.length,
      difficulty: setup.difficulty,
      timeControl: setup.timeControl,
      hintCount: hintCount,
      game: game,
      setup: setup,
    );
    await loadAchievements(now: completedAt);
    return true;
  }

  @override
  Future<List<MatchHistoryEntry>> loadHistory({
    MatchHistoryFilter filter = MatchHistoryFilter.all,
  }) async {
    final List<MatchHistoryEntry> result =
        _entries.values
            .where((entry) => entry.matches(filter))
            .toList(growable: false)
          ..sort(
            (left, right) => right.completedAt.compareTo(left.completedAt),
          );
    return List<MatchHistoryEntry>.unmodifiable(result);
  }

  @override
  Future<ChessStatistics> loadStatistics({DateTime? now}) async {
    final DateTime? resetAt = _resetAt;
    final List<MatchHistoryEntry> entries = _entries.values
        .where(
          (entry) => resetAt == null || !entry.completedAt.isBefore(resetAt),
        )
        .toList(growable: false);
    if (entries.isEmpty) {
      return ChessStatistics(
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        computerWinsByDifficulty: const <ComputerDifficulty, int>{},
        whiteWins: 0,
        whiteLosses: 0,
        whiteDraws: 0,
        blackWins: 0,
        blackLosses: 0,
        blackDraws: 0,
        averageGameLength: Duration.zero,
        fastestWin: null,
        longestGame: null,
        totalMoves: 0,
        totalCaptures: 0,
        totalHintsUsed: 0,
        challengesCompleted: 0,
        coinsEarned: 0,
        hintsEarned: 0,
        puzzlesSolved: 0,
        currentStreak: 0,
        bestStreak: 0,
        resetAt: resetAt,
      );
    }
    final List<int> durations = entries
        .map((entry) => entry.duration.inSeconds)
        .toList(growable: false);
    final List<int> winningDurations = entries
        .where((entry) => entry.outcome == MatchOutcome.win)
        .map((entry) => entry.duration.inSeconds)
        .toList(growable: false);
    final Map<ComputerDifficulty, int> computerWins =
        <ComputerDifficulty, int>{};
    for (final MatchHistoryEntry entry in entries) {
      if (entry.mode == GameMode.computer &&
          entry.outcome == MatchOutcome.win) {
        computerWins.update(
          entry.difficulty,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return ChessStatistics(
      gamesPlayed: entries.length,
      wins: _outcomeCount(entries, MatchOutcome.win),
      losses: _outcomeCount(entries, MatchOutcome.loss),
      draws: _outcomeCount(entries, MatchOutcome.draw),
      computerWinsByDifficulty: Map<ComputerDifficulty, int>.unmodifiable(
        computerWins,
      ),
      whiteWins: _sideOutcomeCount(entries, PieceColor.white, MatchOutcome.win),
      whiteLosses: _sideOutcomeCount(
        entries,
        PieceColor.white,
        MatchOutcome.loss,
      ),
      whiteDraws: _sideOutcomeCount(
        entries,
        PieceColor.white,
        MatchOutcome.draw,
      ),
      blackWins: _sideOutcomeCount(entries, PieceColor.black, MatchOutcome.win),
      blackLosses: _sideOutcomeCount(
        entries,
        PieceColor.black,
        MatchOutcome.loss,
      ),
      blackDraws: _sideOutcomeCount(
        entries,
        PieceColor.black,
        MatchOutcome.draw,
      ),
      averageGameLength: Duration(
        seconds: durations.reduce((a, b) => a + b) ~/ durations.length,
      ),
      fastestWin: winningDurations.isEmpty
          ? null
          : Duration(seconds: winningDurations.reduce((a, b) => a < b ? a : b)),
      longestGame: Duration(seconds: durations.reduce((a, b) => a > b ? a : b)),
      totalMoves: entries.fold(0, (sum, entry) => sum + entry.moveCount),
      totalCaptures: entries.fold(
        0,
        (sum, entry) => sum + entry.game.capturedPieces.length,
      ),
      totalHintsUsed: entries.fold(0, (sum, entry) => sum + entry.hintCount),
      challengesCompleted: 0,
      coinsEarned: 0,
      hintsEarned: 0,
      puzzlesSolved: 0,
      currentStreak: 0,
      bestStreak: 0,
      resetAt: resetAt,
    );
  }

  @override
  Future<List<AchievementProgress>> loadAchievements({DateTime? now}) async {
    final DateTime timestamp = (now ?? DateTime.now()).toUtc();
    final List<MatchHistoryEntry> entries = _entries.values.toList(
      growable: false,
    );
    final Map<AchievementId, int> progress = _achievementProgress(entries);
    for (final AchievementId id in AchievementCatalog.ordered) {
      if ((progress[id] ?? 0) >= AchievementCatalog.target(id)) {
        _unlockedAt.putIfAbsent(id, () => timestamp);
      }
    }
    return <AchievementProgress>[
      for (final AchievementId id in AchievementCatalog.ordered)
        AchievementProgress(
          id: id,
          progress: progress[id] ?? 0,
          target: AchievementCatalog.target(id),
          unlockedAt: _unlockedAt[id],
        ),
    ];
  }

  @override
  Future<void> resetStatistics(DateTime now) async {
    _resetAt = now.toUtc();
  }

  Map<AchievementId, int> _achievementProgress(
    List<MatchHistoryEntry> entries,
  ) {
    final int moves = entries.fold(0, (sum, entry) => sum + entry.moveCount);
    final int wins = _outcomeCount(entries, MatchOutcome.win);
    return <AchievementId, int>{
      AchievementId.firstMove: moves,
      AchievementId.firstWin: wins,
      AchievementId.firstCheckmate: entries
          .where(
            (entry) =>
                entry.outcome == MatchOutcome.win &&
                entry.resultReason == 'checkmate',
          )
          .length,
      AchievementId.winAsBlack: entries
          .where(
            (entry) =>
                entry.outcome == MatchOutcome.win &&
                entry.playerColor == PieceColor.black,
          )
          .length,
      AchievementId.castleSuccessfully: entries
          .where(
            (entry) => entry.game.moveRecords.any(
              (record) => record.san.startsWith('O-O'),
            ),
          )
          .length,
      AchievementId.promotePawn: entries
          .where(
            (entry) => entry.game.moveRecords.any(
              (record) => record.move.promotion != null,
            ),
          )
          .length,
      AchievementId.noHintVictory: entries
          .where(
            (entry) =>
                entry.outcome == MatchOutcome.win && entry.hintCount == 0,
          )
          .length,
      AchievementId.tenGamesPlayed: entries.length,
      AchievementId.fiftyGamesPlayed: entries.length,
      AchievementId.localMatchCompleted: entries
          .where((entry) => entry.mode == GameMode.local)
          .length,
      AchievementId.friendMatchCompleted: entries
          .where((entry) => entry.mode == GameMode.friend)
          .length,
    };
  }

  int _outcomeCount(List<MatchHistoryEntry> entries, MatchOutcome outcome) {
    return entries.where((entry) => entry.outcome == outcome).length;
  }

  int _sideOutcomeCount(
    List<MatchHistoryEntry> entries,
    PieceColor color,
    MatchOutcome outcome,
  ) {
    return entries
        .where(
          (entry) => entry.playerColor == color && entry.outcome == outcome,
        )
        .length;
  }

  Duration _safeDuration(DateTime startedAt, DateTime completedAt) {
    final Duration duration = completedAt.toUtc().difference(startedAt.toUtc());
    return duration.isNegative ? Duration.zero : duration;
  }
}
