import 'daily_challenge.dart';
import 'local_date.dart';
import 'reward_wallet.dart';

final class ChallengeDashboard {
  const ChallengeDashboard({
    required this.date,
    required this.today,
    required this.history,
    required this.wallet,
  });

  final LocalDate date;
  final List<DailyChallenge> today;
  final List<DailyChallenge> history;
  final RewardWallet wallet;

  int get completedToday =>
      today.where((DailyChallenge challenge) => challenge.isCompleted).length;

  int get currentStreak {
    final Set<LocalDate> completedDates = <LocalDate>{
      for (final DailyChallenge challenge in <DailyChallenge>[
        ...today,
        ...history,
      ])
        if (challenge.isCompleted) challenge.date,
    };
    LocalDate cursor = completedDates.contains(date) ? date : date.previousDay;
    int streak = 0;
    while (completedDates.contains(cursor)) {
      streak++;
      cursor = cursor.previousDay;
    }
    return streak;
  }
}

final class ClaimRewardResult {
  const ClaimRewardResult({
    required this.dashboard,
    required this.newlyClaimed,
  });

  final ChallengeDashboard dashboard;
  final bool newlyClaimed;
}
