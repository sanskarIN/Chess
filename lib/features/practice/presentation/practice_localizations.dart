import '../../../l10n/app_localizations.dart';
import '../domain/training_puzzle.dart';
import '../domain/tutorial_lesson.dart';

String tutorialTitle(AppLocalizations strings, TutorialTopic topic) {
  return switch (topic) {
    TutorialTopic.boardCoordinates => strings.tutorialBoardCoordinatesTitle,
    TutorialTopic.pawnMovement => strings.tutorialPawnMovementTitle,
    TutorialTopic.knightMovement => strings.tutorialKnightMovementTitle,
    TutorialTopic.bishopMovement => strings.tutorialBishopMovementTitle,
    TutorialTopic.rookMovement => strings.tutorialRookMovementTitle,
    TutorialTopic.queenMovement => strings.tutorialQueenMovementTitle,
    TutorialTopic.kingMovement => strings.tutorialKingMovementTitle,
    TutorialTopic.captures => strings.tutorialCapturesTitle,
    TutorialTopic.check => strings.tutorialCheckTitle,
    TutorialTopic.checkmate => strings.tutorialCheckmateTitle,
    TutorialTopic.castling => strings.tutorialCastlingTitle,
    TutorialTopic.enPassant => strings.tutorialEnPassantTitle,
    TutorialTopic.promotion => strings.tutorialPromotionTitle,
    TutorialTopic.draws => strings.tutorialDrawsTitle,
    TutorialTopic.basicTactics => strings.tutorialBasicTacticsTitle,
    TutorialTopic.openingPrinciples => strings.tutorialOpeningPrinciplesTitle,
    TutorialTopic.basicEndgames => strings.tutorialBasicEndgamesTitle,
  };
}

String tutorialObjective(AppLocalizations strings, TutorialTopic topic) {
  return switch (topic) {
    TutorialTopic.boardCoordinates => strings.tutorialBoardCoordinatesObjective,
    TutorialTopic.pawnMovement => strings.tutorialPawnMovementObjective,
    TutorialTopic.knightMovement => strings.tutorialKnightMovementObjective,
    TutorialTopic.bishopMovement => strings.tutorialBishopMovementObjective,
    TutorialTopic.rookMovement => strings.tutorialRookMovementObjective,
    TutorialTopic.queenMovement => strings.tutorialQueenMovementObjective,
    TutorialTopic.kingMovement => strings.tutorialKingMovementObjective,
    TutorialTopic.captures => strings.tutorialCapturesObjective,
    TutorialTopic.check => strings.tutorialCheckObjective,
    TutorialTopic.checkmate => strings.tutorialCheckmateObjective,
    TutorialTopic.castling => strings.tutorialCastlingObjective,
    TutorialTopic.enPassant => strings.tutorialEnPassantObjective,
    TutorialTopic.promotion => strings.tutorialPromotionObjective,
    TutorialTopic.draws => strings.tutorialDrawsObjective,
    TutorialTopic.basicTactics => strings.tutorialBasicTacticsObjective,
    TutorialTopic.openingPrinciples =>
      strings.tutorialOpeningPrinciplesObjective,
    TutorialTopic.basicEndgames => strings.tutorialBasicEndgamesObjective,
  };
}

String tutorialInstructions(AppLocalizations strings, TutorialTopic topic) {
  return switch (topic) {
    TutorialTopic.boardCoordinates =>
      strings.tutorialBoardCoordinatesInstructions,
    TutorialTopic.pawnMovement => strings.tutorialPawnMovementInstructions,
    TutorialTopic.knightMovement => strings.tutorialKnightMovementInstructions,
    TutorialTopic.bishopMovement => strings.tutorialBishopMovementInstructions,
    TutorialTopic.rookMovement => strings.tutorialRookMovementInstructions,
    TutorialTopic.queenMovement => strings.tutorialQueenMovementInstructions,
    TutorialTopic.kingMovement => strings.tutorialKingMovementInstructions,
    TutorialTopic.captures => strings.tutorialCapturesInstructions,
    TutorialTopic.check => strings.tutorialCheckInstructions,
    TutorialTopic.checkmate => strings.tutorialCheckmateInstructions,
    TutorialTopic.castling => strings.tutorialCastlingInstructions,
    TutorialTopic.enPassant => strings.tutorialEnPassantInstructions,
    TutorialTopic.promotion => strings.tutorialPromotionInstructions,
    TutorialTopic.draws => strings.tutorialDrawsInstructions,
    TutorialTopic.basicTactics => strings.tutorialBasicTacticsInstructions,
    TutorialTopic.openingPrinciples =>
      strings.tutorialOpeningPrinciplesInstructions,
    TutorialTopic.basicEndgames => strings.tutorialBasicEndgamesInstructions,
  };
}

String puzzleTitle(AppLocalizations strings, TrainingPuzzle puzzle) {
  return switch (puzzle.titleLocalizationKey) {
    'puzzleFoolsMateTitle' => strings.puzzleFoolsMateTitle,
    'puzzleScholarPatternTitle' => strings.puzzleScholarPatternTitle,
    'puzzleHangingQueenTitle' => strings.puzzleHangingQueenTitle,
    'puzzleOpeningCenterTitle' => strings.puzzleOpeningCenterTitle,
    'puzzlePromotionEndgameTitle' => strings.puzzlePromotionEndgameTitle,
    _ => puzzle.id,
  };
}

String puzzleDescription(AppLocalizations strings, TrainingPuzzle puzzle) {
  return switch (puzzle.descriptionLocalizationKey) {
    'puzzleFoolsMateDescription' => strings.puzzleFoolsMateDescription,
    'puzzleScholarPatternDescription' =>
      strings.puzzleScholarPatternDescription,
    'puzzleHangingQueenDescription' => strings.puzzleHangingQueenDescription,
    'puzzleOpeningCenterDescription' => strings.puzzleOpeningCenterDescription,
    'puzzlePromotionEndgameDescription' =>
      strings.puzzlePromotionEndgameDescription,
    _ => puzzle.id,
  };
}

String puzzleTypeLabel(AppLocalizations strings, TrainingPuzzleType type) {
  return switch (type) {
    TrainingPuzzleType.mateInOne => strings.mateInOne,
    TrainingPuzzleType.mateInTwo => strings.mateInTwo,
    TrainingPuzzleType.tactic => strings.tactics,
    TrainingPuzzleType.opening => strings.openings,
    TrainingPuzzleType.endgame => strings.endgames,
  };
}
