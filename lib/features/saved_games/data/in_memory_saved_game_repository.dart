import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/domain/notation/pgn_codec.dart';
import '../domain/saved_game.dart';
import 'saved_game_repository.dart';

final class InMemorySavedGameRepository implements SavedGameRepository {
  final Map<String, SavedGame> _records = <String, SavedGame>{};

  @override
  Future<List<SavedGame>> loadAll() async {
    final List<SavedGame> result = _records.values.map(_clone).toList()
      ..sort((SavedGame a, SavedGame b) => b.updatedAt.compareTo(a.updatedAt));
    return List<SavedGame>.unmodifiable(result);
  }

  @override
  Future<SavedGame?> load(String savedGameId) async {
    final SavedGame? value = _records[savedGameId];
    return value == null ? null : _clone(value);
  }

  @override
  Future<SavedGame> save({
    String? savedGameId,
    required String title,
    String? notes,
    required GameSetup setup,
    required ChessGame game,
    required DateTime now,
  }) async {
    final String safeTitle = _validateTitle(title);
    final String id =
        savedGameId ??
        'save-${now.toUtc().microsecondsSinceEpoch}-${_records.length}';
    final SavedGame? existing = _records[id];
    final SavedGame value = SavedGame(
      id: id,
      title: safeTitle,
      notes: _normalizeNotes(notes),
      setup: setup,
      game: _copyGame(game, 'saved-$id'),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    _records[id] = value;
    return _clone(value);
  }

  @override
  Future<SavedGame> rename({
    required String savedGameId,
    required String title,
    required DateTime now,
  }) async {
    final SavedGame? current = _records[savedGameId];
    if (current == null) {
      throw const SavedGameFailure('not_found');
    }
    final SavedGame renamed = SavedGame(
      id: current.id,
      title: _validateTitle(title),
      notes: current.notes,
      setup: current.setup,
      game: current.game,
      createdAt: current.createdAt,
      updatedAt: now,
    );
    _records[savedGameId] = renamed;
    return _clone(renamed);
  }

  @override
  Future<void> delete(String savedGameId) async {
    _records.remove(savedGameId);
  }

  @override
  Future<SavedGame> importFen({
    required String fen,
    required String title,
    required DateTime now,
  }) {
    final ChessGame game = ChessGame(
      gameId: 'fen-${now.toUtc().microsecondsSinceEpoch}',
      initialPosition: FenCodec.decode(fen),
    );
    return save(title: title, setup: _importSetup(), game: game, now: now);
  }

  @override
  Future<SavedGame> importPgn({
    required String pgn,
    required String title,
    required DateTime now,
  }) {
    final PgnDocument document = const PgnCodec().decode(
      pgn,
      gameId: 'pgn-${now.toUtc().microsecondsSinceEpoch}',
    );
    return save(
      title: title,
      setup: _importSetup(
        white: document.tags['White'],
        black: document.tags['Black'],
      ),
      game: document.game,
      now: now,
    );
  }

  SavedGame _clone(SavedGame value) {
    return SavedGame(
      id: value.id,
      title: value.title,
      notes: value.notes,
      setup: value.setup,
      game: _copyGame(value.game, value.game.gameId),
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  ChessGame _copyGame(ChessGame source, String gameId) {
    return ChessGame.restore(
      gameId: gameId,
      initialPosition: source.initialPosition,
      moves: source.moveRecords.map((record) => record.move),
      declaredResult: source.result?.notation,
    );
  }

  GameSetup _importSetup({String? white, String? black}) {
    return GameSetup.friend(
      whitePlayerName: _safePlayerName(white, 'White'),
      blackPlayerName: _safePlayerName(black, 'Black'),
      localColor: PieceColor.white,
    );
  }

  String _safePlayerName(String? value, String fallback) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty
        ? fallback
        : normalized.substring(0, normalized.length.clamp(0, 40));
  }

  String _validateTitle(String title) {
    final String normalized = title.trim();
    if (normalized.isEmpty || normalized.length > 80) {
      throw const SavedGameFailure('invalid_title');
    }
    return normalized;
  }

  String? _normalizeNotes(String? notes) {
    final String normalized = notes?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
