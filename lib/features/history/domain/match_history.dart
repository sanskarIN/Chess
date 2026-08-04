import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/piece_color.dart';

enum MatchOutcome { win, loss, draw }

enum MatchHistoryFilter {
  all,
  wins,
  losses,
  draws,
  computer,
  local,
  friend,
  white,
  black,
  beginner,
  intermediate,
  expert,
  grandmaster,
}

final class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.id,
    required this.mode,
    required this.opponentName,
    required this.playerColor,
    required this.outcome,
    required this.resultReason,
    required this.completedAt,
    required this.duration,
    required this.moveCount,
    required this.difficulty,
    required this.timeControl,
    required this.hintCount,
    required this.game,
    required this.setup,
  });

  final String id;
  final GameMode mode;
  final String opponentName;
  final PieceColor playerColor;
  final MatchOutcome outcome;
  final String resultReason;
  final DateTime completedAt;
  final Duration duration;
  final int moveCount;
  final ComputerDifficulty difficulty;
  final TimeControl timeControl;
  final int hintCount;
  final ChessGame game;
  final GameSetup setup;

  bool matches(MatchHistoryFilter filter) {
    return switch (filter) {
      MatchHistoryFilter.all => true,
      MatchHistoryFilter.wins => outcome == MatchOutcome.win,
      MatchHistoryFilter.losses => outcome == MatchOutcome.loss,
      MatchHistoryFilter.draws => outcome == MatchOutcome.draw,
      MatchHistoryFilter.computer => mode == GameMode.computer,
      MatchHistoryFilter.local => mode == GameMode.local,
      MatchHistoryFilter.friend => mode == GameMode.friend,
      MatchHistoryFilter.white => playerColor == PieceColor.white,
      MatchHistoryFilter.black => playerColor == PieceColor.black,
      MatchHistoryFilter.beginner =>
        mode == GameMode.computer && difficulty == ComputerDifficulty.beginner,
      MatchHistoryFilter.intermediate =>
        mode == GameMode.computer &&
            difficulty == ComputerDifficulty.intermediate,
      MatchHistoryFilter.expert =>
        mode == GameMode.computer && difficulty == ComputerDifficulty.expert,
      MatchHistoryFilter.grandmaster =>
        mode == GameMode.computer &&
            difficulty == ComputerDifficulty.grandmaster,
    };
  }
}

final class ChessStatistics {
  const ChessStatistics({
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.computerWinsByDifficulty,
    required this.whiteWins,
    required this.whiteLosses,
    required this.whiteDraws,
    required this.blackWins,
    required this.blackLosses,
    required this.blackDraws,
    required this.averageGameLength,
    required this.fastestWin,
    required this.longestGame,
    required this.totalMoves,
    required this.totalCaptures,
    required this.totalHintsUsed,
    required this.challengesCompleted,
    required this.coinsEarned,
    required this.hintsEarned,
    required this.puzzlesSolved,
    required this.currentStreak,
    required this.bestStreak,
    required this.resetAt,
  });

  static const ChessStatistics empty = ChessStatistics(
    gamesPlayed: 0,
    wins: 0,
    losses: 0,
    draws: 0,
    computerWinsByDifficulty: <ComputerDifficulty, int>{},
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
    resetAt: null,
  );

  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final Map<ComputerDifficulty, int> computerWinsByDifficulty;
  final int whiteWins;
  final int whiteLosses;
  final int whiteDraws;
  final int blackWins;
  final int blackLosses;
  final int blackDraws;
  final Duration averageGameLength;
  final Duration? fastestWin;
  final Duration? longestGame;
  final int totalMoves;
  final int totalCaptures;
  final int totalHintsUsed;
  final int challengesCompleted;
  final int coinsEarned;
  final int hintsEarned;
  final int puzzlesSolved;
  final int currentStreak;
  final int bestStreak;
  final DateTime? resetAt;
}

enum AchievementId {
  firstMove,
  firstWin,
  firstCheckmate,
  winAsBlack,
  castleSuccessfully,
  promotePawn,
  puzzleBeginner,
  puzzleSolver,
  challengeStarter,
  challengeMaster,
  noHintVictory,
  tenGamesPlayed,
  fiftyGamesPlayed,
  localMatchCompleted,
  friendMatchCompleted,
}

final class AchievementProgress {
  const AchievementProgress({
    required this.id,
    required this.progress,
    required this.target,
    required this.unlockedAt,
  });

  final AchievementId id;
  final int progress;
  final int target;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;
}
