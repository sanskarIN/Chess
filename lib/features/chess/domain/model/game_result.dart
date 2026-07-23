import 'piece_color.dart';

enum GameResultReason {
  checkmate,
  stalemate,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial,
  drawAgreement,
  resignation,
  timeout,
  adjudication,
}

final class GameResult {
  const GameResult._({required this.winner, required this.reason});

  const GameResult.whiteWin(GameResultReason reason)
    : this._(winner: PieceColor.white, reason: reason);

  const GameResult.blackWin(GameResultReason reason)
    : this._(winner: PieceColor.black, reason: reason);

  const GameResult.draw(GameResultReason reason)
    : this._(winner: null, reason: reason);

  final PieceColor? winner;
  final GameResultReason reason;

  bool get isDraw => winner == null;

  String get notation {
    return switch (winner) {
      PieceColor.white => '1-0',
      PieceColor.black => '0-1',
      null => '1/2-1/2',
    };
  }

  @override
  bool operator ==(Object other) {
    return other is GameResult &&
        other.winner == winner &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(winner, reason);

  @override
  String toString() => '$notation (${reason.name})';
}
