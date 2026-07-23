import 'package:sqflite/sqflite.dart';

import '../../../core/database/transactional_database.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/domain/notation/pgn_codec.dart';
import '../domain/saved_game.dart';
import 'game_setup_codec.dart';
import 'saved_game_repository.dart';

final class SqfliteSavedGameRepository implements SavedGameRepository {
  const SqfliteSavedGameRepository({required this.database});

  final TransactionalDatabase database;

  @override
  Future<List<SavedGame>> loadAll() {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.rawQuery('''
SELECT s.*, g.*
FROM saved_games s
JOIN games g ON g.game_id = s.game_id
ORDER BY s.updated_at DESC, s.saved_game_id ASC
''');
      final List<SavedGame> result = <SavedGame>[];
      for (final Map<String, Object?> row in rows) {
        result.add(await _fromRow(transaction, row));
      }
      return List<SavedGame>.unmodifiable(result);
    });
  }

  @override
  Future<SavedGame?> load(String savedGameId) {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.rawQuery(
        '''
SELECT s.*, g.*
FROM saved_games s
JOIN games g ON g.game_id = s.game_id
WHERE s.saved_game_id = ?
LIMIT 1
''',
        <Object?>[savedGameId],
      );
      return rows.isEmpty ? null : _fromRow(transaction, rows.single);
    });
  }

  @override
  Future<SavedGame> save({
    String? savedGameId,
    required String title,
    String? notes,
    required GameSetup setup,
    required ChessGame game,
    required DateTime now,
  }) {
    final String safeTitle = _validateTitle(title);
    final String id =
        savedGameId ?? 'save-${now.toUtc().microsecondsSinceEpoch}';
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> existing = await transaction.query(
        'saved_games',
        where: 'saved_game_id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      final int timestamp = now.toUtc().millisecondsSinceEpoch;
      final int createdAt = existing.isEmpty
          ? timestamp
          : existing.single['created_at']! as int;
      final String gameId = existing.isEmpty
          ? 'saved-game-$id'
          : existing.single['game_id']! as String;
      final String? result = game.result?.notation;
      final String? resultReason = game.result?.reason.name;
      await transaction.insert('games', <String, Object?>{
        'game_id': gameId,
        'mode': setup.mode.name,
        'status': game.result == null ? 'active' : 'completed',
        'initial_fen': FenCodec.encode(game.initialPosition),
        'current_fen': FenCodec.encode(game.position),
        'white_name': setup.whitePlayerName,
        'black_name': setup.blackPlayerName,
        'result': result,
        'result_reason': resultReason,
        'time_control_json': GameSetupCodec.encode(setup),
        'difficulty': setup.difficulty.name,
        'started_at': createdAt,
        'completed_at': game.result == null ? null : timestamp,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.delete(
        'moves',
        where: 'game_id = ?',
        whereArgs: <Object?>[gameId],
      );
      for (final record in game.moveRecords) {
        await transaction.insert('moves', <String, Object?>{
          'move_id': '$gameId:${record.ply}',
          'game_id': gameId,
          'ply': record.ply,
          'from_square': record.move.from.algebraic,
          'to_square': record.move.to.algebraic,
          'promotion': record.move.promotion?.fenLetter,
          'san': record.san,
          'fen_after': FenCodec.encode(record.positionAfter),
          'elapsed_millis': 0,
          'created_at': timestamp,
        });
      }
      await transaction.insert('saved_games', <String, Object?>{
        'saved_game_id': id,
        'game_id': gameId,
        'title': safeTitle,
        'notes': _normalizeNotes(notes),
        'created_at': createdAt,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final List<Map<String, Object?>> rows = await transaction.rawQuery(
        '''
SELECT s.*, g.*
FROM saved_games s
JOIN games g ON g.game_id = s.game_id
WHERE s.saved_game_id = ?
LIMIT 1
''',
        <Object?>[id],
      );
      return _fromRow(transaction, rows.single);
    });
  }

  @override
  Future<SavedGame> rename({
    required String savedGameId,
    required String title,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      final int count = await transaction.update(
        'saved_games',
        <String, Object?>{
          'title': _validateTitle(title),
          'updated_at': now.toUtc().millisecondsSinceEpoch,
        },
        where: 'saved_game_id = ?',
        whereArgs: <Object?>[savedGameId],
      );
      if (count != 1) {
        throw const SavedGameFailure('not_found');
      }
      final List<Map<String, Object?>> rows = await transaction.rawQuery(
        '''
SELECT s.*, g.*
FROM saved_games s
JOIN games g ON g.game_id = s.game_id
WHERE s.saved_game_id = ?
LIMIT 1
''',
        <Object?>[savedGameId],
      );
      return _fromRow(transaction, rows.single);
    });
  }

  @override
  Future<void> delete(String savedGameId) {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'saved_games',
        columns: const <String>['game_id'],
        where: 'saved_game_id = ?',
        whereArgs: <Object?>[savedGameId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return;
      }
      final String gameId = rows.single['game_id']! as String;
      await transaction.delete(
        'saved_games',
        where: 'saved_game_id = ?',
        whereArgs: <Object?>[savedGameId],
      );
      await transaction.delete(
        'games',
        where: 'game_id = ?',
        whereArgs: <Object?>[gameId],
      );
    });
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

  Future<SavedGame> _fromRow(
    Transaction transaction,
    Map<String, Object?> row,
  ) async {
    final String gameId = row['game_id']! as String;
    final List<Map<String, Object?>> moveRows = await transaction.query(
      'moves',
      columns: const <String>['from_square', 'to_square', 'promotion'],
      where: 'game_id = ?',
      whereArgs: <Object?>[gameId],
      orderBy: 'ply ASC',
    );
    final List<Move> moves = moveRows
        .map(
          (Map<String, Object?> moveRow) => Move.fromUci(
            '${moveRow['from_square']}${moveRow['to_square']}'
            '${moveRow['promotion'] ?? ''}',
          ),
        )
        .toList(growable: false);
    final ChessGame game = ChessGame.restore(
      gameId: gameId,
      initialPosition: FenCodec.decode(row['initial_fen']! as String),
      moves: moves,
      declaredResult: row['result'] as String?,
    );
    return SavedGame(
      id: row['saved_game_id']! as String,
      title: row['title']! as String,
      notes: row['notes'] as String?,
      setup: GameSetupCodec.decode(row['time_control_json'] as String?),
      game: game,
      createdAt: _dateTime(row['created_at']),
      updatedAt: _dateTime(row['updated_at']),
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
    if (normalized.isEmpty) {
      return fallback;
    }
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
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

  DateTime _dateTime(Object? milliseconds) {
    if (milliseconds is! int) {
      throw const FormatException('Saved game timestamp is missing.');
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
}
