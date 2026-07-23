import '../../chess/domain/board/square.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/position.dart';

enum TutorialTopic {
  boardCoordinates,
  pawnMovement,
  knightMovement,
  bishopMovement,
  rookMovement,
  queenMovement,
  kingMovement,
  captures,
  check,
  checkmate,
  castling,
  enPassant,
  promotion,
  draws,
  basicTactics,
  openingPrinciples,
  basicEndgames,
}

final class TutorialLesson {
  const TutorialLesson({
    required this.id,
    required this.topic,
    required this.initialPosition,
    required this.expectedMove,
    required this.expectedSquare,
    required this.rewardCoins,
  }) : assert((expectedMove == null) != (expectedSquare == null)),
       assert(rewardCoins >= 0);

  final String id;
  final TutorialTopic topic;
  final Position initialPosition;
  final Move? expectedMove;
  final Square? expectedSquare;
  final int rewardCoins;
}
