enum PracticeExerciseType {
  freeBoard,
  pieceMovementGuide,
  legalMovePractice,
  mateInOne,
  mateInTwo,
  tactic,
  opening,
  endgame,
  customFen,
}

final class PracticeExercise {
  const PracticeExercise({
    required this.id,
    required this.type,
    required this.titleLocalizationKey,
    required this.descriptionLocalizationKey,
    required this.rewardCoins,
  }) : assert(rewardCoins >= 0);

  final String id;
  final PracticeExerciseType type;
  final String titleLocalizationKey;
  final String descriptionLocalizationKey;
  final int rewardCoins;
}
