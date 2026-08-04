import 'match_history.dart';

abstract final class AchievementCatalog {
  static const List<AchievementId> ordered = <AchievementId>[
    AchievementId.firstMove,
    AchievementId.firstWin,
    AchievementId.firstCheckmate,
    AchievementId.winAsBlack,
    AchievementId.castleSuccessfully,
    AchievementId.promotePawn,
    AchievementId.puzzleBeginner,
    AchievementId.puzzleSolver,
    AchievementId.challengeStarter,
    AchievementId.challengeMaster,
    AchievementId.noHintVictory,
    AchievementId.tenGamesPlayed,
    AchievementId.fiftyGamesPlayed,
    AchievementId.localMatchCompleted,
    AchievementId.friendMatchCompleted,
  ];

  static int target(AchievementId id) {
    return switch (id) {
      AchievementId.puzzleSolver ||
      AchievementId.challengeMaster ||
      AchievementId.tenGamesPlayed => 10,
      AchievementId.fiftyGamesPlayed => 50,
      _ => 1,
    };
  }
}
