import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../../core/database/transactional_database.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/model/move.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../saved_games/data/game_setup_codec.dart';
import '../domain/achievement_catalog.dart';
import '../domain/match_history.dart';
import 'match_history_repository.dart';

final class SqfliteMatchHistoryRepository implements MatchHistoryRepository {
  const SqfliteMatchHistoryRepository({required this.database});

  static const String _resetKey = 'reset_at';
  static const String _globalScope = 'global';

  final TransactionalDatabase database;

  @override
  Future<bool> recordCompletedMatch({
    required GameSetup setup,
    required ChessGame game,
    required DateTime startedAt,
    required DateTime completedAt,
    required int hintCount,
  }) async {
    final result = game.result;
    if (result == null) {
      return false;
    }
    if (hintCount < 0) {
      throw ArgumentError.value(
        hintCount,
        'hintCount',
        'Must not be negative.',
      );
    }
    final String historyId = 'history-${game.gameId}';
    final String storedGameId = 'history-game-${game.gameId}';
    final bool inserted = await database.runTransaction((
      Transaction transaction,
    ) async {
      final List<Map<String, Object?>> existing = await transaction.query(
        'match_history',
        columns: const <String>['history_id'],
        where: 'history_id = ?',
        whereArgs: <Object?>[historyId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return false;
      }

      final DateTime safeCompletedAt = completedAt.toUtc();
      final DateTime safeStartedAt = startedAt.toUtc().isAfter(safeCompletedAt)
          ? safeCompletedAt
          : startedAt.toUtc();
      final int completedTimestamp = safeCompletedAt.millisecondsSinceEpoch;
      final int startedTimestamp = safeStartedAt.millisecondsSinceEpoch;
      final PieceColor perspective = setup.humanColor ?? PieceColor.white;
      final PieceColor? winner = result.winner;
      final MatchOutcome outcome = winner == null
          ? MatchOutcome.draw
          : winner == perspective
          ? MatchOutcome.win
          : MatchOutcome.loss;

      await transaction.insert('games', <String, Object?>{
        'game_id': storedGameId,
        'mode': setup.mode.name,
        'status': 'completed',
        'initial_fen': FenCodec.encode(game.initialPosition),
        'current_fen': FenCodec.encode(game.position),
        'white_name': setup.whitePlayerName,
        'black_name': setup.blackPlayerName,
        'result': result.notation,
        'result_reason': result.reason.name,
        'time_control_json': GameSetupCodec.encode(setup),
        'difficulty': setup.difficulty.name,
        'started_at': startedTimestamp,
        'completed_at': completedTimestamp,
        'updated_at': completedTimestamp,
      });
      for (final record in game.moveRecords) {
        await transaction.insert('moves', <String, Object?>{
          'move_id': '$storedGameId:${record.ply}',
          'game_id': storedGameId,
          'ply': record.ply,
          'from_square': record.move.from.algebraic,
          'to_square': record.move.to.algebraic,
          'promotion': record.move.promotion?.fenLetter,
          'san': record.san,
          'fen_after': FenCodec.encode(record.positionAfter),
          'elapsed_millis': 0,
          'created_at': completedTimestamp,
        });
      }
      await transaction.insert('match_history', <String, Object?>{
        'history_id': historyId,
        'game_id': storedGameId,
        'opponent_type': setup.mode.name,
        'player_color': perspective.name,
        'result': outcome.name,
        'result_reason': result.reason.name,
        'duration_seconds': safeCompletedAt.difference(safeStartedAt).inSeconds,
        'move_count': game.moveRecords.length,
        'hint_count': hintCount,
        'completed_at': completedTimestamp,
      });
      return true;
    });
    if (inserted) {
      await loadAchievements(now: completedAt);
    }
    return inserted;
  }

  @override
  Future<List<MatchHistoryEntry>> loadHistory({
    MatchHistoryFilter filter = MatchHistoryFilter.all,
  }) {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.rawQuery('''
SELECT
  h.history_id,
  h.game_id,
  h.opponent_type,
  h.player_color,
  h.result AS history_result,
  h.result_reason AS history_result_reason,
  h.duration_seconds,
  h.move_count,
  h.hint_count,
  h.completed_at AS history_completed_at,
  g.initial_fen,
  g.result AS game_result,
  g.time_control_json
FROM match_history h
JOIN games g ON g.game_id = h.game_id
ORDER BY h.completed_at DESC, h.history_id ASC
''');
      final List<MatchHistoryEntry> entries = <MatchHistoryEntry>[];
      for (final Map<String, Object?> row in rows) {
        final MatchHistoryEntry entry = await _entryFromRow(transaction, row);
        if (entry.matches(filter)) {
          entries.add(entry);
        }
      }
      return List<MatchHistoryEntry>.unmodifiable(entries);
    });
  }

  @override
  Future<ChessStatistics> loadStatistics({DateTime? now}) {
    return database.runTransaction((Transaction transaction) async {
      final DateTime referenceNow = (now ?? DateTime.now()).toUtc();
      final int resetTimestamp = await _readResetTimestamp(transaction);
      final List<Map<String, Object?>> historyRows = await transaction.rawQuery(
        '''
SELECT h.*, g.difficulty
FROM match_history h
JOIN games g ON g.game_id = h.game_id
WHERE h.completed_at >= ?
''',
        <Object?>[resetTimestamp],
      );

      int wins = 0;
      int losses = 0;
      int draws = 0;
      int whiteWins = 0;
      int whiteLosses = 0;
      int whiteDraws = 0;
      int blackWins = 0;
      int blackLosses = 0;
      int blackDraws = 0;
      int totalSeconds = 0;
      int? fastestWinSeconds;
      int? longestSeconds;
      int totalMoves = 0;
      int totalHints = 0;
      final Map<ComputerDifficulty, int> computerWins =
          <ComputerDifficulty, int>{};

      for (final Map<String, Object?> row in historyRows) {
        final MatchOutcome outcome = _enumByName(
          MatchOutcome.values,
          row['result'] as String?,
          MatchOutcome.draw,
        );
        final PieceColor color = _enumByName(
          PieceColor.values,
          row['player_color'] as String?,
          PieceColor.white,
        );
        final int duration = _int(row['duration_seconds']);
        totalSeconds += duration;
        longestSeconds = longestSeconds == null
            ? duration
            : math.max(longestSeconds, duration);
        totalMoves += _int(row['move_count']);
        totalHints += _int(row['hint_count']);
        if (outcome == MatchOutcome.win) {
          wins++;
          fastestWinSeconds = fastestWinSeconds == null
              ? duration
              : math.min(fastestWinSeconds, duration);
          if (row['opponent_type'] == GameMode.computer.name) {
            final ComputerDifficulty difficulty = _enumByName(
              ComputerDifficulty.values,
              row['difficulty'] as String?,
              ComputerDifficulty.beginner,
            );
            computerWins.update(
              difficulty,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        } else if (outcome == MatchOutcome.loss) {
          losses++;
        } else {
          draws++;
        }
        if (color == PieceColor.white) {
          if (outcome == MatchOutcome.win) {
            whiteWins++;
          } else if (outcome == MatchOutcome.loss) {
            whiteLosses++;
          } else {
            whiteDraws++;
          }
        } else {
          if (outcome == MatchOutcome.win) {
            blackWins++;
          } else if (outcome == MatchOutcome.loss) {
            blackLosses++;
          } else {
            blackDraws++;
          }
        }
      }

      final int captures = _int(
        (await transaction.rawQuery(
          '''
SELECT COUNT(*) AS value
FROM moves m
JOIN match_history h ON h.game_id = m.game_id
WHERE h.completed_at >= ? AND m.san LIKE '%x%'
''',
          <Object?>[resetTimestamp],
        )).single['value'],
      );
      final int challenges = _int(
        (await transaction.rawQuery(
          '''
SELECT COUNT(*) AS value
FROM challenge_progress
WHERE completed_at IS NOT NULL AND completed_at >= ?
''',
          <Object?>[resetTimestamp],
        )).single['value'],
      );
      final List<Map<String, Object?>> rewardRows = await transaction.rawQuery(
        '''
SELECT asset_type, COALESCE(SUM(amount), 0) AS value
FROM reward_transactions
WHERE amount > 0 AND timestamp >= ?
GROUP BY asset_type
''',
        <Object?>[resetTimestamp],
      );
      int coinsEarned = 0;
      int hintsEarned = 0;
      for (final Map<String, Object?> row in rewardRows) {
        if (row['asset_type'] == 'coin') {
          coinsEarned = _int(row['value']);
        } else if (row['asset_type'] == 'hint') {
          hintsEarned = _int(row['value']);
        }
      }
      final int puzzlesSolved = _int(
        (await transaction.rawQuery(
          '''
SELECT COUNT(*) AS value
FROM practice_progress
WHERE exercise_type = 'puzzle'
  AND solved_at IS NOT NULL
  AND solved_at >= ?
''',
          <Object?>[resetTimestamp],
        )).single['value'],
      );
      final List<Map<String, Object?>> streakRows = await transaction.rawQuery(
        '''
SELECT DISTINCT d.local_date
FROM daily_challenges d
JOIN challenge_progress p ON p.challenge_id = d.challenge_id
WHERE p.completed_at IS NOT NULL AND p.completed_at >= ?
ORDER BY d.local_date ASC
''',
        <Object?>[resetTimestamp],
      );
      final ({int current, int best}) streaks = _streaks(
        streakRows
            .map((row) => row['local_date'] as String)
            .toList(growable: false),
        referenceNow,
      );
      final int games = historyRows.length;
      return ChessStatistics(
        gamesPlayed: games,
        wins: wins,
        losses: losses,
        draws: draws,
        computerWinsByDifficulty: Map<ComputerDifficulty, int>.unmodifiable(
          computerWins,
        ),
        whiteWins: whiteWins,
        whiteLosses: whiteLosses,
        whiteDraws: whiteDraws,
        blackWins: blackWins,
        blackLosses: blackLosses,
        blackDraws: blackDraws,
        averageGameLength: games == 0
            ? Duration.zero
            : Duration(seconds: totalSeconds ~/ games),
        fastestWin: fastestWinSeconds == null
            ? null
            : Duration(seconds: fastestWinSeconds),
        longestGame: longestSeconds == null
            ? null
            : Duration(seconds: longestSeconds),
        totalMoves: totalMoves,
        totalCaptures: captures,
        totalHintsUsed: totalHints,
        challengesCompleted: challenges,
        coinsEarned: coinsEarned,
        hintsEarned: hintsEarned,
        puzzlesSolved: puzzlesSolved,
        currentStreak: streaks.current,
        bestStreak: streaks.best,
        resetAt: resetTimestamp == 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(resetTimestamp, isUtc: true),
      );
    });
  }

  @override
  Future<List<AchievementProgress>> loadAchievements({DateTime? now}) {
    return database.runTransaction((Transaction transaction) async {
      final DateTime timestamp = (now ?? DateTime.now()).toUtc();
      final Map<AchievementId, int> progress = await _achievementProgress(
        transaction,
      );
      for (final AchievementId id in AchievementCatalog.ordered) {
        final int target = AchievementCatalog.target(id);
        final int current = progress[id] ?? 0;
        final int safeProgress = math.min(current, target);
        final int? unlockedAt = current >= target
            ? timestamp.millisecondsSinceEpoch
            : null;
        await transaction.rawInsert(
          '''
INSERT INTO achievements (
  achievement_id,
  progress,
  target,
  unlocked_at,
  reward_claimed_at,
  definition_version,
  updated_at
) VALUES (?, ?, ?, ?, NULL, 1, ?)
ON CONFLICT(achievement_id) DO UPDATE SET
  progress = MAX(achievements.progress, excluded.progress),
  target = excluded.target,
  unlocked_at = COALESCE(achievements.unlocked_at, excluded.unlocked_at),
  definition_version = excluded.definition_version,
  updated_at = excluded.updated_at
''',
          <Object?>[
            id.name,
            safeProgress,
            target,
            unlockedAt,
            timestamp.millisecondsSinceEpoch,
          ],
        );
      }
      final List<Map<String, Object?>> rows = await transaction.query(
        'achievements',
      );
      final Map<String, Map<String, Object?>> byId =
          <String, Map<String, Object?>>{
            for (final Map<String, Object?> row in rows)
              row['achievement_id']! as String: row,
          };
      return <AchievementProgress>[
        for (final AchievementId id in AchievementCatalog.ordered)
          AchievementProgress(
            id: id,
            progress: _int(byId[id.name]?['progress']),
            target: _int(byId[id.name]?['target']),
            unlockedAt: _dateTime(byId[id.name]?['unlocked_at']),
          ),
      ];
    });
  }

  @override
  Future<void> resetStatistics(DateTime now) {
    return database.runTransaction((Transaction transaction) async {
      final int timestamp = now.toUtc().millisecondsSinceEpoch;
      await transaction.insert('statistics', <String, Object?>{
        'statistic_key': _resetKey,
        'scope': _globalScope,
        'integer_value': timestamp,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<MatchHistoryEntry> _entryFromRow(
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
          (moveRow) => Move.fromUci(
            '${moveRow['from_square']}${moveRow['to_square']}'
            '${moveRow['promotion'] ?? ''}',
          ),
        )
        .toList(growable: false);
    final ChessGame game = ChessGame.restore(
      gameId: gameId,
      initialPosition: FenCodec.decode(row['initial_fen']! as String),
      moves: moves,
      declaredResult: row['game_result'] as String?,
    );
    final GameSetup setup = GameSetupCodec.decode(
      row['time_control_json']! as String,
    );
    final PieceColor perspective = _enumByName(
      PieceColor.values,
      row['player_color'] as String?,
      PieceColor.white,
    );
    return MatchHistoryEntry(
      id: row['history_id']! as String,
      mode: _enumByName(
        GameMode.values,
        row['opponent_type'] as String?,
        setup.mode,
      ),
      opponentName: perspective == PieceColor.white
          ? setup.blackPlayerName
          : setup.whitePlayerName,
      playerColor: perspective,
      outcome: _enumByName(
        MatchOutcome.values,
        row['history_result'] as String?,
        MatchOutcome.draw,
      ),
      resultReason: row['history_result_reason']! as String,
      completedAt: _dateTime(row['history_completed_at'])!,
      duration: Duration(seconds: _int(row['duration_seconds'])),
      moveCount: _int(row['move_count']),
      difficulty: setup.difficulty,
      timeControl: setup.timeControl,
      hintCount: _int(row['hint_count']),
      game: game,
      setup: setup,
    );
  }

  Future<int> _readResetTimestamp(Transaction transaction) async {
    final List<Map<String, Object?>> rows = await transaction.query(
      'statistics',
      columns: const <String>['integer_value'],
      where: 'statistic_key = ? AND scope = ?',
      whereArgs: const <Object?>[_resetKey, _globalScope],
      limit: 1,
    );
    return rows.isEmpty ? 0 : _int(rows.single['integer_value']);
  }

  Future<Map<AchievementId, int>> _achievementProgress(
    Transaction transaction,
  ) async {
    Future<int> count(String sql, [List<Object?>? arguments]) async {
      final List<Map<String, Object?>> rows = await transaction.rawQuery(
        sql,
        arguments,
      );
      return _int(rows.single['value']);
    }

    final int moves = await count(
      'SELECT COUNT(*) AS value FROM moves m '
      'JOIN match_history h ON h.game_id = m.game_id',
    );
    final int wins = await count(
      "SELECT COUNT(*) AS value FROM match_history WHERE result = 'win'",
    );
    final int checkmates = await count(
      "SELECT COUNT(*) AS value FROM match_history "
      "WHERE result = 'win' AND result_reason = 'checkmate'",
    );
    final int blackWins = await count(
      "SELECT COUNT(*) AS value FROM match_history "
      "WHERE result = 'win' AND player_color = 'black'",
    );
    final int castled = await count(
      "SELECT COUNT(DISTINCT h.history_id) AS value FROM match_history h "
      "JOIN moves m ON m.game_id = h.game_id WHERE m.san LIKE 'O-O%'",
    );
    final int promoted = await count(
      'SELECT COUNT(DISTINCT h.history_id) AS value FROM match_history h '
      'JOIN moves m ON m.game_id = h.game_id WHERE m.promotion IS NOT NULL',
    );
    final int puzzles = await count(
      "SELECT COUNT(*) AS value FROM practice_progress "
      "WHERE exercise_type = 'puzzle' AND solved_at IS NOT NULL",
    );
    final int challenges = await count(
      'SELECT COUNT(*) AS value FROM challenge_progress '
      'WHERE completed_at IS NOT NULL',
    );
    final int noHintWins = await count(
      "SELECT COUNT(*) AS value FROM match_history "
      "WHERE result = 'win' AND hint_count = 0",
    );
    final int games = await count(
      'SELECT COUNT(*) AS value FROM match_history',
    );
    final int localGames = await count(
      "SELECT COUNT(*) AS value FROM match_history "
      "WHERE opponent_type = 'local'",
    );
    final int friendGames = await count(
      "SELECT COUNT(*) AS value FROM match_history "
      "WHERE opponent_type = 'friend'",
    );
    return <AchievementId, int>{
      AchievementId.firstMove: moves,
      AchievementId.firstWin: wins,
      AchievementId.firstCheckmate: checkmates,
      AchievementId.winAsBlack: blackWins,
      AchievementId.castleSuccessfully: castled,
      AchievementId.promotePawn: promoted,
      AchievementId.puzzleBeginner: puzzles,
      AchievementId.puzzleSolver: puzzles,
      AchievementId.challengeStarter: challenges,
      AchievementId.challengeMaster: challenges,
      AchievementId.noHintVictory: noHintWins,
      AchievementId.tenGamesPlayed: games,
      AchievementId.fiftyGamesPlayed: games,
      AchievementId.localMatchCompleted: localGames,
      AchievementId.friendMatchCompleted: friendGames,
    };
  }

  ({int current, int best}) _streaks(List<String> values, DateTime now) {
    if (values.isEmpty) {
      return (current: 0, best: 0);
    }
    final List<DateTime> dates =
        values
            .map(_parseLocalDate)
            .whereType<DateTime>()
            .toSet()
            .toList(growable: false)
          ..sort();
    if (dates.isEmpty) {
      return (current: 0, best: 0);
    }
    int best = 1;
    int run = 1;
    for (int index = 1; index < dates.length; index++) {
      if (dates[index].difference(dates[index - 1]).inDays == 1) {
        run++;
        best = math.max(best, run);
      } else {
        run = 1;
      }
    }
    final DateTime today = DateTime.utc(now.year, now.month, now.day);
    final int age = today.difference(dates.last).inDays;
    int current = 0;
    if (age == 0 || age == 1) {
      current = 1;
      for (int index = dates.length - 1; index > 0; index--) {
        if (dates[index].difference(dates[index - 1]).inDays != 1) {
          break;
        }
        current++;
      }
    }
    return (current: current, best: best);
  }

  DateTime? _parseLocalDate(String value) {
    final List<String> parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    final DateTime parsed = DateTime.utc(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day
        ? parsed
        : null;
  }

  T _enumByName<T>(List<T> values, String? name, T fallback) {
    for (final T value in values) {
      if ((value as Enum).name == name) {
        return value;
      }
    }
    return fallback;
  }

  int _int(Object? value) => value is int ? value : 0;

  DateTime? _dateTime(Object? value) {
    return value is int
        ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
        : null;
  }
}
