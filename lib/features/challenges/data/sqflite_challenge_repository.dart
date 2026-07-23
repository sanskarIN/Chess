import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../../app/app_version.dart';
import '../../../core/database/transactional_database.dart';
import '../domain/challenge_dashboard.dart';
import '../domain/challenge_event.dart';
import '../domain/daily_challenge.dart';
import '../domain/local_date.dart';
import '../domain/reward_wallet.dart';
import 'challenge_repository.dart';

final class SqfliteChallengeRepository implements ChallengeRepository {
  const SqfliteChallengeRepository({required this.database});

  final TransactionalDatabase database;

  @override
  Future<ChallengeDashboard> load({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      await _initializeWallet(transaction, now);
      await _ensureDefinitions(transaction, definitions, now);
      return _readDashboard(transaction, date);
    });
  }

  @override
  Future<ChallengeDashboard> recordEvent({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required ChallengeEvent event,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      await _initializeWallet(transaction, now);
      await _ensureDefinitions(transaction, definitions, now);
      final List<Map<String, Object?>> existing = await transaction.query(
        'challenge_events',
        columns: const <String>['event_id'],
        where: 'event_id = ?',
        whereArgs: <Object?>['${date.value}:${event.id}'],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return _readDashboard(transaction, date);
      }
      await transaction.insert('challenge_events', <String, Object?>{
        'event_id': '${date.value}:${event.id}',
        'challenge_type': event.type.name,
        'amount': event.amount,
        'local_date': date.value,
        'recorded_at': now.toUtc().millisecondsSinceEpoch,
      });
      final List<Map<String, Object?>> rows = await transaction.rawQuery(
        '''
SELECT d.challenge_id, d.target_value, p.current_value, p.completed_at
FROM daily_challenges d
JOIN challenge_progress p ON p.challenge_id = d.challenge_id
WHERE d.local_date = ? AND d.challenge_type = ?
''',
        <Object?>[date.value, event.type.name],
      );
      for (final Map<String, Object?> row in rows) {
        final int target = row['target_value']! as int;
        final int current = row['current_value']! as int;
        final int next = (current + event.amount).clamp(0, target);
        await transaction.update(
          'challenge_progress',
          <String, Object?>{
            'current_value': next,
            'completed_at': next >= target
                ? (row['completed_at'] ?? now.toUtc().millisecondsSinceEpoch)
                : null,
            'updated_at': now.toUtc().millisecondsSinceEpoch,
          },
          where: 'challenge_id = ?',
          whereArgs: <Object?>[row['challenge_id']],
        );
      }
      return _readDashboard(transaction, date);
    });
  }

  @override
  Future<ClaimRewardResult> claim({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required String challengeId,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      await _initializeWallet(transaction, now);
      await _ensureDefinitions(transaction, definitions, now);
      final List<Map<String, Object?>> rows = await transaction.rawQuery(
        '''
SELECT d.*, p.current_value, p.completed_at, p.claimed_at
FROM daily_challenges d
JOIN challenge_progress p ON p.challenge_id = d.challenge_id
WHERE d.challenge_id = ? AND d.local_date = ?
LIMIT 1
''',
        <Object?>[challengeId, date.value],
      );
      if (rows.isEmpty) {
        throw const EconomyFailure('challenge_not_found');
      }
      final DailyChallenge challenge = _challengeFromRow(rows.single);
      if (!challenge.isCompleted) {
        throw const EconomyFailure('challenge_incomplete');
      }
      if (challenge.isClaimed) {
        return ClaimRewardResult(
          dashboard: await _readDashboard(transaction, date),
          newlyClaimed: false,
        );
      }

      bool credited = false;
      if (challenge.reward.coins > 0) {
        credited =
            await _insertLedgerEntry(
              transaction,
              type: RewardTransactionType.challengeReward,
              asset: RewardAsset.coin,
              amount: challenge.reward.coins,
              source: 'challenge:${challenge.id}',
              relatedChallengeId: challenge.id,
              now: now,
            ) ||
            credited;
      }
      if (challenge.reward.hints > 0) {
        credited =
            await _insertLedgerEntry(
              transaction,
              type: RewardTransactionType.challengeReward,
              asset: RewardAsset.hint,
              amount: challenge.reward.hints,
              source: 'challenge:${challenge.id}',
              relatedChallengeId: challenge.id,
              now: now,
            ) ||
            credited;
      }
      await transaction.update(
        'challenge_progress',
        <String, Object?>{
          'claimed_at': now.toUtc().millisecondsSinceEpoch,
          'updated_at': now.toUtc().millisecondsSinceEpoch,
        },
        where: 'challenge_id = ? AND claimed_at IS NULL',
        whereArgs: <Object?>[challenge.id],
      );
      return ClaimRewardResult(
        dashboard: await _readDashboard(transaction, date),
        newlyClaimed: credited,
      );
    });
  }

  @override
  Future<HintPurchase> purchaseHint({
    required HintPaymentMethod method,
    required String requestId,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      await _initializeWallet(transaction, now);
      final RewardAsset asset = method == HintPaymentMethod.hint
          ? RewardAsset.hint
          : RewardAsset.coin;
      final int cost = method == HintPaymentMethod.hint ? 1 : 25;
      final String source = 'hint:$requestId';
      final List<Map<String, Object?>> existing = await transaction.query(
        'reward_transactions',
        columns: const <String>['amount'],
        where: 'transaction_type = ? AND asset_type = ? AND source = ?',
        whereArgs: <Object?>[
          RewardTransactionType.hintPurchase.name,
          asset.name,
          source,
        ],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return HintPurchase(
          wallet: await _readWallet(transaction),
          assetSpent: asset,
          amountSpent: -(existing.single['amount']! as int),
          duplicate: true,
        );
      }
      final RewardWallet wallet = await _readWallet(transaction);
      if (wallet.balance(asset) < cost) {
        throw EconomyFailure(
          asset == RewardAsset.coin
              ? 'insufficient_coins'
              : 'insufficient_hints',
        );
      }
      await _insertLedgerEntry(
        transaction,
        type: RewardTransactionType.hintPurchase,
        asset: asset,
        amount: -cost,
        source: source,
        relatedChallengeId: null,
        now: now,
      );
      return HintPurchase(
        wallet: await _readWallet(transaction),
        assetSpent: asset,
        amountSpent: cost,
        duplicate: false,
      );
    });
  }

  @override
  Future<List<RewardLedgerEntry>> readLedger() {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'reward_transactions',
        orderBy: 'ledger_sequence DESC',
      );
      return List<RewardLedgerEntry>.unmodifiable(
        rows.map(_ledgerEntryFromRow),
      );
    });
  }

  @override
  Future<LedgerIntegrityReport> verifyLedgerIntegrity() {
    return database.runTransaction((Transaction transaction) async {
      final List<Map<String, Object?>> rows = await transaction.query(
        'reward_transactions',
        orderBy: 'ledger_sequence ASC',
      );
      String previous = '';
      int checked = 0;
      for (final Map<String, Object?> row in rows) {
        final RewardLedgerEntry entry = _ledgerEntryFromRow(row);
        if (entry.integrityHash.startsWith('migrated-v2-')) {
          previous = entry.integrityHash;
          checked++;
          continue;
        }
        if (entry.previousIntegrityHash != previous ||
            entry.integrityHash != _hashEntry(entry, previous)) {
          return LedgerIntegrityReport(isValid: false, checkedEntries: checked);
        }
        previous = entry.integrityHash;
        checked++;
      }
      return LedgerIntegrityReport(isValid: true, checkedEntries: checked);
    });
  }

  @override
  Future<RewardWallet> grantEarnedReward({
    required RewardTransactionType type,
    required String source,
    required int coins,
    required int hints,
    required DateTime now,
  }) {
    if (coins < 0 || hints < 0 || (coins == 0 && hints == 0)) {
      throw const EconomyFailure('invalid_reward');
    }
    return database.runTransaction((Transaction transaction) async {
      await _initializeWallet(transaction, now);
      if (coins > 0) {
        await _insertLedgerEntry(
          transaction,
          type: type,
          asset: RewardAsset.coin,
          amount: coins,
          source: source,
          relatedChallengeId: null,
          now: now,
        );
      }
      if (hints > 0) {
        await _insertLedgerEntry(
          transaction,
          type: type,
          asset: RewardAsset.hint,
          amount: hints,
          source: source,
          relatedChallengeId: null,
          now: now,
        );
      }
      return _readWallet(transaction);
    });
  }

  @override
  Future<ChallengeDashboard> resetDate({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required DateTime now,
  }) {
    return database.runTransaction((Transaction transaction) async {
      await _ensureDefinitions(transaction, definitions, now);
      await transaction.delete(
        'challenge_events',
        where: 'local_date = ?',
        whereArgs: <Object?>[date.value],
      );
      await transaction.rawUpdate(
        '''
UPDATE challenge_progress
SET current_value = 0, completed_at = NULL, updated_at = ?
WHERE claimed_at IS NULL
  AND challenge_id IN (
    SELECT challenge_id FROM daily_challenges WHERE local_date = ?
  )
''',
        <Object?>[now.toUtc().millisecondsSinceEpoch, date.value],
      );
      return _readDashboard(transaction, date);
    });
  }

  Future<void> _ensureDefinitions(
    Transaction transaction,
    List<DailyChallenge> definitions,
    DateTime now,
  ) async {
    for (final DailyChallenge challenge in definitions) {
      await transaction.insert('daily_challenges', <String, Object?>{
        'challenge_id': challenge.id,
        'local_date': challenge.date.value,
        'challenge_type': challenge.type.name,
        'title_key': challenge.titleLocalizationKey,
        'description_key': challenge.descriptionLocalizationKey,
        'target_value': challenge.targetValue,
        'reward_type': challenge.reward.type.name,
        'reward_amount': challenge.reward.coins > 0
            ? challenge.reward.coins
            : challenge.reward.hints,
        'difficulty': challenge.difficulty.name,
        'eligibility_json': jsonEncode(challenge.eligibilityConditions),
        'definition_version': challenge.version,
        'coin_reward': challenge.reward.coins,
        'hint_reward': challenge.reward.hints,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await transaction.insert('challenge_progress', <String, Object?>{
        'challenge_id': challenge.id,
        'current_value': 0,
        'completed_at': null,
        'claimed_at': null,
        'updated_at': challenge.date.start.toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (definitions.isNotEmpty) {
      await transaction.insert('app_settings', <String, Object?>{
        'setting_key': 'daily_challenge_last_date',
        'value_json': jsonEncode(definitions.first.date.value),
        'value_type': 'string',
        'updated_at': now.toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _initializeWallet(Transaction transaction, DateTime now) async {
    final int timestamp = now.toUtc().millisecondsSinceEpoch;
    for (final RewardAsset asset in RewardAsset.values) {
      await transaction.insert('wallet_balances', <String, Object?>{
        'asset_type': asset.name,
        'balance': 0,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await _insertLedgerEntry(
      transaction,
      type: RewardTransactionType.onboardingReward,
      asset: RewardAsset.coin,
      amount: 50,
      source: 'onboarding-v1',
      relatedChallengeId: null,
      now: now,
    );
    await _insertLedgerEntry(
      transaction,
      type: RewardTransactionType.onboardingReward,
      asset: RewardAsset.hint,
      amount: 1,
      source: 'onboarding-v1',
      relatedChallengeId: null,
      now: now,
    );
  }

  Future<bool> _insertLedgerEntry(
    Transaction transaction, {
    required RewardTransactionType type,
    required RewardAsset asset,
    required int amount,
    required String source,
    required String? relatedChallengeId,
    required DateTime now,
  }) async {
    final List<Map<String, Object?>> duplicate = await transaction.query(
      'reward_transactions',
      columns: const <String>['transaction_id'],
      where: 'transaction_type = ? AND asset_type = ? AND source = ?',
      whereArgs: <Object?>[type.name, asset.name, source],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      return false;
    }
    final RewardWallet wallet = await _readWallet(transaction);
    final int before = wallet.balance(asset);
    final int after = before + amount;
    if (after < 0) {
      throw const EconomyFailure('negative_balance');
    }
    final List<Map<String, Object?>> previousRows = await transaction.query(
      'reward_transactions',
      columns: const <String>['ledger_sequence', 'integrity_hash'],
      orderBy: 'ledger_sequence DESC',
      limit: 1,
    );
    final String previous = previousRows.isEmpty
        ? ''
        : previousRows.single['integrity_hash']! as String;
    final int sequence = previousRows.isEmpty
        ? 1
        : (previousRows.single['ledger_sequence']! as int) + 1;
    final int timestamp = now.toUtc().millisecondsSinceEpoch;
    final String idSeed =
        '$timestamp\n${type.name}\n${asset.name}\n$source\n$amount';
    final String id =
        '$timestamp-${asset.name}-${sha256.convert(utf8.encode(idSeed)).toString().substring(0, 16)}';
    final RewardLedgerEntry draft = RewardLedgerEntry(
      id: id,
      sequence: sequence,
      type: type,
      asset: asset,
      amount: amount,
      balanceBefore: before,
      balanceAfter: after,
      source: source,
      timestamp: now,
      relatedChallengeId: relatedChallengeId,
      appVersion: AppVersion.name,
      previousIntegrityHash: previous,
      integrityHash: '',
    );
    await transaction.insert('reward_transactions', <String, Object?>{
      'transaction_id': draft.id,
      'ledger_sequence': draft.sequence,
      'transaction_type': draft.type.name,
      'asset_type': draft.asset.name,
      'amount': draft.amount,
      'balance_before': draft.balanceBefore,
      'balance_after': draft.balanceAfter,
      'source': draft.source,
      'timestamp': timestamp,
      'related_challenge_id': draft.relatedChallengeId,
      'app_version': draft.appVersion,
      'previous_integrity_hash': previous,
      'integrity_hash': _hashEntry(draft, previous),
    });
    await transaction.update(
      'wallet_balances',
      <String, Object?>{'balance': after, 'updated_at': timestamp},
      where: 'asset_type = ?',
      whereArgs: <Object?>[asset.name],
    );
    return true;
  }

  Future<ChallengeDashboard> _readDashboard(
    Transaction transaction,
    LocalDate date,
  ) async {
    final List<Map<String, Object?>> rows = await transaction.rawQuery('''
SELECT d.*, p.current_value, p.completed_at, p.claimed_at
FROM daily_challenges d
JOIN challenge_progress p ON p.challenge_id = d.challenge_id
ORDER BY d.local_date DESC, d.challenge_id ASC
''');
    final List<DailyChallenge> all = rows.map(_challengeFromRow).toList();
    return ChallengeDashboard(
      date: date,
      today: List<DailyChallenge>.unmodifiable(
        all.where((DailyChallenge challenge) => challenge.date == date),
      ),
      history: List<DailyChallenge>.unmodifiable(
        all.where((DailyChallenge challenge) => challenge.date != date),
      ),
      wallet: await _readWallet(transaction),
    );
  }

  Future<RewardWallet> _readWallet(Transaction transaction) async {
    final List<Map<String, Object?>> rows = await transaction.query(
      'wallet_balances',
    );
    int coins = 0;
    int hints = 0;
    for (final Map<String, Object?> row in rows) {
      if (row['asset_type'] == RewardAsset.coin.name) {
        coins = row['balance']! as int;
      } else if (row['asset_type'] == RewardAsset.hint.name) {
        hints = row['balance']! as int;
      }
    }
    return RewardWallet(coins: coins, hints: hints);
  }

  DailyChallenge _challengeFromRow(Map<String, Object?> row) {
    final Object? eligibility = jsonDecode(row['eligibility_json']! as String);
    return DailyChallenge(
      id: row['challenge_id']! as String,
      titleLocalizationKey: row['title_key']! as String,
      descriptionLocalizationKey: row['description_key']! as String,
      type: ChallengeType.values.byName(row['challenge_type']! as String),
      targetValue: row['target_value']! as int,
      currentProgress: row['current_value']! as int,
      reward: ChallengeReward(
        coins: row['coin_reward']! as int,
        hints: row['hint_reward']! as int,
      ),
      date: LocalDate.parse(row['local_date']! as String),
      completedAt: _dateTime(row['completed_at']),
      claimedAt: _dateTime(row['claimed_at']),
      version: row['definition_version']! as int,
      difficulty: ChallengeDifficulty.values.byName(
        row['difficulty']! as String,
      ),
      eligibilityConditions: eligibility is Map<String, Object?>
          ? Map<String, Object?>.unmodifiable(eligibility)
          : const <String, Object?>{},
    );
  }

  RewardLedgerEntry _ledgerEntryFromRow(Map<String, Object?> row) {
    return RewardLedgerEntry(
      id: row['transaction_id']! as String,
      sequence: row['ledger_sequence']! as int,
      type: RewardTransactionType.values.byName(
        row['transaction_type']! as String,
      ),
      asset: RewardAsset.values.byName(row['asset_type']! as String),
      amount: row['amount']! as int,
      balanceBefore: row['balance_before']! as int,
      balanceAfter: row['balance_after']! as int,
      source: row['source']! as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        row['timestamp']! as int,
        isUtc: true,
      ),
      relatedChallengeId: row['related_challenge_id'] as String?,
      appVersion: row['app_version']! as String,
      previousIntegrityHash: row['previous_integrity_hash']! as String,
      integrityHash: row['integrity_hash']! as String,
    );
  }

  DateTime? _dateTime(Object? milliseconds) {
    return milliseconds is int
        ? DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true)
        : null;
  }

  String _hashEntry(RewardLedgerEntry entry, String previous) {
    final String canonical = <Object?>[
      entry.id,
      entry.sequence,
      entry.type.name,
      entry.asset.name,
      entry.amount,
      entry.balanceBefore,
      entry.balanceAfter,
      entry.source,
      entry.timestamp.toUtc().millisecondsSinceEpoch,
      entry.relatedChallengeId ?? '',
      entry.appVersion,
      previous,
    ].join('\n');
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
