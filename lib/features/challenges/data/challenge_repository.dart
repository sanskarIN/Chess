import '../domain/challenge_dashboard.dart';
import '../domain/challenge_event.dart';
import '../domain/daily_challenge.dart';
import '../domain/local_date.dart';
import '../domain/reward_wallet.dart';

abstract interface class ChallengeRepository {
  Future<ChallengeDashboard> load({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required DateTime now,
  });

  Future<ChallengeDashboard> recordEvent({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required ChallengeEvent event,
    required DateTime now,
  });

  Future<ClaimRewardResult> claim({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required String challengeId,
    required DateTime now,
  });

  Future<HintPurchase> purchaseHint({
    required HintPaymentMethod method,
    required String requestId,
    required DateTime now,
  });

  Future<List<RewardLedgerEntry>> readLedger();

  Future<LedgerIntegrityReport> verifyLedgerIntegrity();

  Future<RewardWallet> grantEarnedReward({
    required RewardTransactionType type,
    required String source,
    required int coins,
    required int hints,
    required DateTime now,
  });

  Future<ChallengeDashboard> resetDate({
    required LocalDate date,
    required List<DailyChallenge> definitions,
    required DateTime now,
  });
}
