import 'package:chess_master/core/database/database_schema.dart';
import 'package:chess_master/core/database/transactional_database.dart';
import 'package:chess_master/features/challenges/data/deterministic_challenge_generator.dart';
import 'package:chess_master/features/challenges/data/sqflite_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/challenge_event.dart';
import 'package:chess_master/features/challenges/domain/daily_challenge.dart';
import 'package:chess_master/features/challenges/domain/local_date.dart';
import 'package:chess_master/features/challenges/domain/reward_wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqfliteChallengeRepository repository;
  final LocalDate date = LocalDate.parse('2026-07-23');
  final DateTime now = DateTime.utc(2026, 7, 23, 12);
  const DeterministicChallengeGenerator generator =
      DeterministicChallengeGenerator();

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');
    await database.transaction((Transaction transaction) async {
      for (final String statement in DatabaseSchema.creationStatements) {
        await transaction.execute(statement);
      }
    });
    repository = SqfliteChallengeRepository(
      database: _FfiTransactionDatabase(database),
    );
  });

  tearDown(() => database.close());

  test(
    'v2 creation SQL produces valid foreign keys and ledger columns',
    () async {
      final List<Map<String, Object?>> check = await database.rawQuery(
        'PRAGMA foreign_key_check',
      );
      final List<Map<String, Object?>> columns = await database.rawQuery(
        'PRAGMA table_info(reward_transactions)',
      );

      expect(check, isEmpty);
      expect(
        columns.map((Map<String, Object?> row) => row['name']),
        containsAll(<String>[
          'ledger_sequence',
          'balance_before',
          'balance_after',
          'related_challenge_id',
          'app_version',
          'previous_integrity_hash',
          'integrity_hash',
        ]),
      );
    },
  );

  test('v1 to v2 migration preserves challenge and reward data', () async {
    final Database legacy = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      await legacy.execute('PRAGMA foreign_keys = ON');
      for (final String statement in DatabaseSchema.version1Statements) {
        await legacy.execute(statement);
      }
      await legacy.insert('daily_challenges', <String, Object?>{
        'challenge_id': 'legacy-challenge',
        'local_date': '2026-07-22',
        'challenge_type': ChallengeType.finishMatch.name,
        'title_key': 'legacyTitle',
        'description_key': 'legacyDescription',
        'target_value': 1,
        'reward_type': 'coins',
        'reward_amount': 20,
        'difficulty': 'easy',
        'eligibility_json': '{}',
        'definition_version': 1,
      });
      await legacy.insert('challenge_progress', <String, Object?>{
        'challenge_id': 'legacy-challenge',
        'current_value': 1,
        'completed_at': now.millisecondsSinceEpoch,
        'claimed_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      await legacy.insert('reward_transactions', <String, Object?>{
        'transaction_id': 'legacy-transaction',
        'transaction_type': RewardTransactionType.challengeReward.name,
        'asset_type': RewardAsset.coin.name,
        'amount': 20,
        'reason_code': 'challenge_reward',
        'source_id': 'legacy-challenge',
        'balance_after': 70,
        'created_at': now.millisecondsSinceEpoch,
      });

      for (final String statement in DatabaseSchema.version2Statements) {
        await legacy.execute(statement);
      }

      final List<Map<String, Object?>> rows = await legacy.query(
        'reward_transactions',
      );
      expect(rows, hasLength(1));
      expect(rows.single['balance_before'], 50);
      expect(rows.single['balance_after'], 70);
      expect(rows.single['related_challenge_id'], 'legacy-challenge');
      expect(
        (await legacy.query(
          'wallet_balances',
          where: 'asset_type = ?',
          whereArgs: <Object?>[RewardAsset.coin.name],
        )).single['balance'],
        70,
      );
      expect(
        await legacy.query(
          'challenge_progress',
          where: 'challenge_id = ?',
          whereArgs: <Object?>['legacy-challenge'],
        ),
        hasLength(1),
      );
    } finally {
      await legacy.close();
    }
  });

  test('claims concurrently but credits a challenge only once', () async {
    final List<DailyChallenge> definitions = generator.generate(date);
    final DailyChallenge challenge = definitions.singleWhere(
      (DailyChallenge value) => value.type == ChallengeType.playLegalMoves,
    );
    await repository.load(date: date, definitions: definitions, now: now);
    expect(
      (await database.query(
        'app_settings',
        where: 'setting_key = ?',
        whereArgs: <Object?>['daily_challenge_last_date'],
      )).single['value_json'],
      '"2026-07-23"',
    );
    for (int index = 0; index < challenge.targetValue; index++) {
      await repository.recordEvent(
        date: date,
        definitions: definitions,
        event: ChallengeEvent(
          id: 'sqlite-move-$index',
          type: ChallengeType.playLegalMoves,
        ),
        now: now.add(Duration(seconds: index)),
      );
    }

    final results = await Future.wait([
      repository.claim(
        date: date,
        definitions: definitions,
        challengeId: challenge.id,
        now: now.add(const Duration(minutes: 1)),
      ),
      repository.claim(
        date: date,
        definitions: definitions,
        challengeId: challenge.id,
        now: now.add(const Duration(minutes: 1)),
      ),
    ]);

    expect(results.where((result) => result.newlyClaimed), hasLength(1));
    expect(results.last.dashboard.wallet.coins, 70);
    final List<RewardLedgerEntry> ledger = await repository.readLedger();
    expect(
      ledger.where(
        (RewardLedgerEntry entry) =>
            entry.type == RewardTransactionType.challengeReward,
      ),
      hasLength(1),
    );
    expect((await repository.verifyLedgerIntegrity()).isValid, isTrue);
  });

  test('hint spending is idempotent and constrained by the wallet', () async {
    await repository.load(
      date: date,
      definitions: generator.generate(date),
      now: now,
    );

    final HintPurchase first = await repository.purchaseHint(
      method: HintPaymentMethod.coins,
      requestId: 'sqlite-hint-1',
      now: now,
    );
    final HintPurchase duplicate = await repository.purchaseHint(
      method: HintPaymentMethod.coins,
      requestId: 'sqlite-hint-1',
      now: now,
    );

    expect(first.wallet.coins, 25);
    expect(duplicate.wallet.coins, 25);
    expect(duplicate.duplicate, isTrue);
    final HintPurchase second = await repository.purchaseHint(
      method: HintPaymentMethod.coins,
      requestId: 'sqlite-hint-2',
      now: now,
    );
    expect(second.wallet.coins, 0);
    await expectLater(
      repository.purchaseHint(
        method: HintPaymentMethod.coins,
        requestId: 'sqlite-hint-3',
        now: now,
      ),
      throwsA(
        isA<EconomyFailure>().having(
          (EconomyFailure failure) => failure.code,
          'code',
          'insufficient_coins',
        ),
      ),
    );
  });
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
