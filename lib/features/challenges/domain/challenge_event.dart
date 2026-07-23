import 'daily_challenge.dart';

final class ChallengeEvent {
  const ChallengeEvent({required this.id, required this.type, this.amount = 1})
    : assert(id != ''),
      assert(amount > 0);

  final String id;
  final ChallengeType type;
  final int amount;
}
