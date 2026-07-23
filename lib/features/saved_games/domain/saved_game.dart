import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';

final class SavedGame {
  const SavedGame({
    required this.id,
    required this.title,
    required this.notes,
    required this.setup,
    required this.game,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? notes;
  final GameSetup setup;
  final ChessGame game;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCompleted => game.result != null;
}

final class SavedGameLaunch {
  const SavedGameLaunch({required this.savedGame});

  final SavedGame savedGame;
}

final class ReviewLaunch {
  const ReviewLaunch({
    required this.game,
    required this.setup,
    this.savedGameId,
  });

  final ChessGame game;
  final GameSetup setup;
  final String? savedGameId;
}

final class SavedGameFailure implements Exception {
  const SavedGameFailure(this.code);

  final String code;

  @override
  String toString() => 'SavedGameFailure($code)';
}
