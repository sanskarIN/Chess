import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../domain/saved_game.dart';

abstract interface class SavedGameRepository {
  Future<List<SavedGame>> loadAll();

  Future<SavedGame?> load(String savedGameId);

  Future<SavedGame> save({
    String? savedGameId,
    required String title,
    String? notes,
    required GameSetup setup,
    required ChessGame game,
    required DateTime now,
  });

  Future<SavedGame> rename({
    required String savedGameId,
    required String title,
    required DateTime now,
  });

  Future<void> delete(String savedGameId);

  Future<SavedGame> importFen({
    required String fen,
    required String title,
    required DateTime now,
  });

  Future<SavedGame> importPgn({
    required String pgn,
    required String title,
    required DateTime now,
  });
}
