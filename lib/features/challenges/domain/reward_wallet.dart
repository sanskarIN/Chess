enum RewardAsset { coin, hint }

final class RewardWallet {
  const RewardWallet({required this.coins, required this.hints})
    : assert(coins >= 0),
      assert(hints >= 0);

  static const RewardWallet empty = RewardWallet(coins: 0, hints: 0);

  final int coins;
  final int hints;

  int balance(RewardAsset asset) {
    return asset == RewardAsset.coin ? coins : hints;
  }
}

enum RewardTransactionType {
  dailyReward,
  challengeReward,
  achievementReward,
  hintPurchase,
  refund,
  migration,
  developerAdjustment,
  reset,
  onboardingReward,
}

final class RewardLedgerEntry {
  const RewardLedgerEntry({
    required this.id,
    required this.sequence,
    required this.type,
    required this.asset,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.source,
    required this.timestamp,
    required this.relatedChallengeId,
    required this.appVersion,
    required this.previousIntegrityHash,
    required this.integrityHash,
  });

  final String id;
  final int sequence;
  final RewardTransactionType type;
  final RewardAsset asset;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String source;
  final DateTime timestamp;
  final String? relatedChallengeId;
  final String appVersion;
  final String previousIntegrityHash;
  final String integrityHash;
}

enum HintPaymentMethod { hint, coins }

final class HintPurchase {
  const HintPurchase({
    required this.wallet,
    required this.assetSpent,
    required this.amountSpent,
    required this.duplicate,
  });

  final RewardWallet wallet;
  final RewardAsset assetSpent;
  final int amountSpent;
  final bool duplicate;
}

final class EconomyFailure implements Exception {
  const EconomyFailure(this.code);

  final String code;

  @override
  String toString() => 'EconomyFailure($code)';
}

final class LedgerIntegrityReport {
  const LedgerIntegrityReport({
    required this.isValid,
    required this.checkedEntries,
  });

  final bool isValid;
  final int checkedEntries;
}
