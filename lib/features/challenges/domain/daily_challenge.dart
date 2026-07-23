import 'local_date.dart';

enum ChallengeType {
  playLegalMoves,
  finishMatch,
  noHintMatch,
  winAsWhite,
  winAsBlack,
  beginnerWin,
  intermediateWin,
  captureQueen,
  castle,
  promotePawn,
  enPassantCapture,
  localMatch,
}

enum ChallengeDifficulty { easy, medium, hard }

enum ChallengeRewardType { coins, hints, coinsAndHints }

final class ChallengeReward {
  const ChallengeReward({this.coins = 0, this.hints = 0})
    : assert(coins >= 0),
      assert(hints >= 0),
      assert(coins > 0 || hints > 0);

  final int coins;
  final int hints;

  ChallengeRewardType get type {
    if (coins > 0 && hints > 0) {
      return ChallengeRewardType.coinsAndHints;
    }
    return coins > 0 ? ChallengeRewardType.coins : ChallengeRewardType.hints;
  }
}

final class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.titleLocalizationKey,
    required this.descriptionLocalizationKey,
    required this.type,
    required this.targetValue,
    required this.currentProgress,
    required this.reward,
    required this.date,
    required this.completedAt,
    required this.claimedAt,
    required this.version,
    required this.difficulty,
    required this.eligibilityConditions,
  }) : assert(targetValue > 0),
       assert(currentProgress >= 0),
       assert(version >= 1);

  final String id;
  final String titleLocalizationKey;
  final String descriptionLocalizationKey;
  final ChallengeType type;
  final int targetValue;
  final int currentProgress;
  final ChallengeReward reward;
  final LocalDate date;
  final DateTime? completedAt;
  final DateTime? claimedAt;
  final int version;
  final Map<String, Object?> eligibilityConditions;
  final ChallengeDifficulty difficulty;

  bool get isCompleted => completedAt != null || currentProgress >= targetValue;
  bool get isClaimed => claimedAt != null;
  double get progress => (currentProgress / targetValue).clamp(0, 1);

  DailyChallenge copyWith({
    int? currentProgress,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? claimedAt,
    bool clearClaimedAt = false,
  }) {
    return DailyChallenge(
      id: id,
      titleLocalizationKey: titleLocalizationKey,
      descriptionLocalizationKey: descriptionLocalizationKey,
      type: type,
      targetValue: targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      reward: reward,
      date: date,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      claimedAt: clearClaimedAt ? null : (claimedAt ?? this.claimedAt),
      version: version,
      difficulty: difficulty,
      eligibilityConditions: eligibilityConditions,
    );
  }
}
