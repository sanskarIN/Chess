import 'package:chess_master/core/database/database_schema.dart';
import 'package:chess_master/core/database/transactional_database.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/notation/fen_codec.dart';
import 'package:chess_master/features/saved_games/application/review_controller.dart';
import 'package:chess_master/features/saved_games/data/sqflite_saved_game_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqfliteSavedGameRepository repository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');
    for (final String statement in DatabaseSchema.creationStatements) {
      await database.execute(statement);
    }
    repository = SqfliteSavedGameRepository(
      database: _FfiTransactionDatabase(database),
    );
  });

  tearDown(() => database.close());

  test(
    'saves, loads, updates, renames, and deletes a complete move list',
    () async {
      final DateTime now = DateTime.utc(2026, 7, 23, 12);
      final ChessGame game = ChessGame(gameId: 'source-game')
        ..play(Move.fromUci('e2e4'))
        ..play(Move.fromUci('e7e5'));
      final GameSetup setup = _setup();

      final saved = await repository.save(
        title: 'First save',
        notes: 'Local only',
        setup: setup,
        game: game,
        now: now,
      );
      expect((await repository.load(saved.id))!.game.moveRecords, hasLength(2));
      expect((await repository.loadAll()).single.notes, 'Local only');

      game.play(Move.fromUci('g1f3'));
      await repository.save(
        savedGameId: saved.id,
        title: 'Updated save',
        setup: setup,
        game: game,
        now: now.add(const Duration(minutes: 1)),
      );
      final renamed = await repository.rename(
        savedGameId: saved.id,
        title: 'Renamed',
        now: now.add(const Duration(minutes: 2)),
      );
      expect(renamed.title, 'Renamed');
      expect(renamed.game.moveRecords, hasLength(3));

      await repository.delete(saved.id);
      expect(await repository.loadAll(), isEmpty);
    },
  );

  test('strictly imports FEN and PGN and rejects malformed input', () async {
    final DateTime now = DateTime.utc(2026, 7, 23);
    final fromFen = await repository.importFen(
      fen: FenCodec.standardInitialPosition,
      title: 'FEN import',
      now: now,
    );
    expect(fromFen.game.position, fromFen.game.initialPosition);

    final fromPgn = await repository.importPgn(
      pgn: '''
[White "Alice"]
[Black "Bob"]
[Result "*"]

1. e4 e5 2. Nf3 *
''',
      title: 'PGN import',
      now: now.add(const Duration(seconds: 1)),
    );
    expect(fromPgn.game.moveRecords, hasLength(3));
    expect(fromPgn.setup.whitePlayerName, 'Alice');

    expect(
      () => repository.importFen(fen: 'not a fen', title: 'Bad', now: now),
      throwsFormatException,
    );
    expect(
      () => repository.importPgn(pgn: '1. e9 *', title: 'Bad', now: now),
      throwsA(anything),
    );
  });

  test('review controller steps through immutable position history', () {
    final ChessGame game = ChessGame(gameId: 'review')
      ..play(Move.fromUci('e2e4'))
      ..play(Move.fromUci('e7e5'));
    final ReviewController controller = ReviewController(
      game: game,
      setup: _setup(),
    );

    expect(controller.cursor, 2);
    controller.first();
    expect(controller.cursor, 0);
    expect(controller.currentFen, FenCodec.standardInitialPosition);
    controller.next();
    expect(controller.cursor, 1);
    controller.last();
    expect(controller.cursor, 2);
    expect(controller.pgn, contains('1. e4 e5'));
  });
}

GameSetup _setup() {
  return GameSetup.local(
    playerOneName: 'Alice',
    playerTwoName: 'Bob',
    defaultPlayerOneName: 'Player 1',
    defaultPlayerTwoName: 'Player 2',
    playerOneSide: PlayerSideChoice.white,
    timeControl: TimeControl.none,
  );
}

final class _FfiTransactionDatabase implements TransactionalDatabase {
  const _FfiTransactionDatabase(this.database);

  final Database database;

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return database.transaction<T>(action);
  }
}
