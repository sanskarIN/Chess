import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../app/app_version.dart';
import '../domain/challenge_dashboard.dart';
import '../domain/challenge_event.dart';
import '../domain/daily_challenge.dart';
import '../domain/local_date.dart';
import '../domain/reward_wallet.dart';
import 'challenge_repository.dart';

final class InMemoryChallengeRepository implements ChallengeRepository {
  final Map<String, DailyChallenge> _challenges = <String, DailyChallenge>{};
  final Set<String> _eventIds = <String>{};
  final List<RewardLedgerEntry> _ledger = <RewardLedgerEntry>[];
  RewardWallet _wallet = RewardWallet.empty;
  bool _initialized = false;

  @override
  Future<ChallengeDashboard> load({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required DateTime now,
  }) async {
    _initializeWallet(now);
    _ensureDefinitions(definitions);
    return _dashboard(date);
  }

  @override
  Future<ChallengeDashboard> recordEvent({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required ChallengeEvent event,
    required DateTime now,
  }) async {
    _initializeWallet(now);
    _ensureDefinitions(definitions);
    if (!_eventIds.add('${date.value}:${event.id}')) {
      return _dashboard(date);
    }
    for (final DailyChallenge challenge in _challenges.values.where(
      (DailyChallenge value) => value.date == date && value.type == event.type,
    )) {
      final int progress = (challenge.currentProgress + event.amount).clamp(
        0,
        challenge.targetValue,
      );
      _challenges[challenge.id] = challenge.copyWith(
        currentProgress: progress,
        completedAt: progress >= challenge.targetValue
            ? (challenge.completedAt ?? now)
            : null,
      );
    }
    return _dashboard(date);
  }

  @override
  Future<ClaimRewardResult> claim({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required String challengeId,
    required DateTime now,
  }) async {
    _initializeWallet(now);
    _ensureDefinitions(definitions);
    final DailyChallenge? challenge = _challenges[challengeId];
    if (challenge == null || challenge.date != date) {
      throw const EconomyFailure('challenge_not_found');
    }
    if (!challenge.isCompleted) {
      throw const EconomyFailure('challenge_incomplete');
    }
    if (challenge.isClaimed) {
      return ClaimRewardResult(
        dashboard: _dashboard(date),
        newlyClaimed: false,
      );
    }
    if (challenge.reward.coins > 0) {
      _applyTransaction(
        type: RewardTransactionType.challengeReward,
        asset: RewardAsset.coin,
        amount: challenge.reward.coins,
        source: 'challenge:${challenge.id}',
        relatedChallengeId: challenge.id,
        now: now,
      );
    }
    if (challenge.reward.hints > 0) {
      _applyTransaction(
        type: RewardTransactionType.challengeReward,
        asset: RewardAsset.hint,
        amount: challenge.reward.hints,
        source: 'challenge:${challenge.id}',
        relatedChallengeId: challenge.id,
        now: now,
      );
    }
    _challenges[challenge.id] = challenge.copyWith(claimedAt: now);
    return ClaimRewardResult(dashboard: _dashboard(date), newlyClaimed: true);
  }

  @override
  Future<HintPurchase> purchaseHint({
    required HintPaymentMethod method,
    required String requestId,
    required DateTime now,
  }) async {
    final RewardAsset asset = method == HintPaymentMethod.hint
        ? RewardAsset.hint
        : RewardAsset.coin;
    final int cost = method == HintPaymentMethod.hint ? 1 : 25;
    final String source = 'hint:$requestId';
    final RewardLedgerEntry? existing = _ledger
        .where(
          (RewardLedgerEntry entry) =>
              entry.type == RewardTransactionType.hintPurchase &&
              entry.asset == asset &&
              entry.source == source,
        )
        .firstOrNull;
    if (existing != null) {
      return HintPurchase(
        wallet: _wallet,
        assetSpent: asset,
        amountSpent: -existing.amount,
        duplicate: true,
      );
    }
    if (_wallet.balance(asset) < cost) {
      throw EconomyFailure(
        asset == RewardAsset.coin ? 'insufficient_coins' : 'insufficient_hints',
      );
    }
    _applyTransaction(
      type: RewardTransactionType.hintPurchase,
      asset: asset,
      amount: -cost,
      source: source,
      relatedChallengeId: null,
      now: now,
    );
    return HintPurchase(
      wallet: _wallet,
      assetSpent: asset,
      amountSpent: cost,
      duplicate: false,
    );
  }

  @override
  Future<List<RewardLedgerEntry>> readLedger() async {
    return List<RewardLedgerEntry>.unmodifiable(_ledger.reversed);
  }

  @override
  Future<LedgerIntegrityReport> verifyLedgerIntegrity() async {
    String previous = '';
    for (final RewardLedgerEntry entry in _ledger) {
      if (entry.previousIntegrityHash != previous ||
          entry.integrityHash != _hashEntry(entry, previous)) {
        return LedgerIntegrityReport(
          isValid: false,
          checkedEntries: _ledger.indexOf(entry),
        );
      }
      previous = entry.integrityHash;
    }
    return LedgerIntegrityReport(isValid: true, checkedEntries: _ledger.length);
  }

  @override
  Future<ChallengeDashboard> resetDate({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required DateTime now,
  }) async {
    _challenges.removeWhere((_, DailyChallenge value) => value.date == date);
    _eventIds.removeWhere((String value) => value.startsWith('${date.value}:'));
    _ensureDefinitions(definitions);
    return _dashboard(date);
  }

  void _initializeWallet(DateTime now) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _applyTransaction(
      type: RewardTransactionType.onboardingReward,
      asset: RewardAsset.coin,
      amount: 50,
      source: 'onboarding-v1',
      relatedChallengeId: null,
      now: now,
    );
    _applyTransaction(
      type: RewardTransactionType.onboardingReward,
      asset: RewardAsset.hint,
      amount: 1,
      source: 'onboarding-v1',
      relatedChallengeId: null,
      now: now,
    );
  }

  void _ensureDefinitions(List<DailyChallenge> definitions) {
    for (final DailyChallenge challenge in definitions) {
      _challenges.putIfAbsent(challenge.id, () => challenge);
    }
  }

  ChallengeDashboard _dashboard(LocalDate date) {
    final List<DailyChallenge> today =
        _challenges.values
            .where((DailyChallenge challenge) => challenge.date == date)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final List<DailyChallenge> history =
        _challenges.values
            .where((DailyChallenge challenge) => challenge.date != date)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return ChallengeDashboard(
      date: date,
      today: List<DailyChallenge>.unmodifiable(today),
      history: List<DailyChallenge>.unmodifiable(history),
      wallet: _wallet,
    );
  }

  void _applyTransaction({
    required RewardTransactionType type,
    required RewardAsset asset,
    required int amount,
    required String source,
    required String? relatedChallengeId,
    required DateTime now,
  }) {
    final int before = _wallet.balance(asset);
    final int after = before + amount;
    if (after < 0) {
      throw const EconomyFailure('negative_balance');
    }
    final String previous = _ledger.isEmpty ? '' : _ledger.last.integrityHash;
    final String id =
        '${now.toUtc().microsecondsSinceEpoch}-${asset.name}-${_ledger.length}';
    final RewardLedgerEntry draft = RewardLedgerEntry(
      id: id,
      sequence: _ledger.length + 1,
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
    final RewardLedgerEntry entry = RewardLedgerEntry(
      id: draft.id,
      sequence: draft.sequence,
      type: draft.type,
      asset: draft.asset,
      amount: draft.amount,
      balanceBefore: draft.balanceBefore,
      balanceAfter: draft.balanceAfter,
      source: draft.source,
      timestamp: draft.timestamp,
      relatedChallengeId: draft.relatedChallengeId,
      appVersion: draft.appVersion,
      previousIntegrityHash: previous,
      integrityHash: _hashEntry(draft, previous),
    );
    _ledger.add(entry);
    _wallet = asset == RewardAsset.coin
        ? RewardWallet(coins: after, hints: _wallet.hints)
        : RewardWallet(coins: _wallet.coins, hints: after);
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
