import 'package:chess_master/features/challenges/data/deterministic_challenge_generator.dart';
import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/challenge_event.dart';
import 'package:chess_master/features/challenges/domain/daily_challenge.dart';
import 'package:chess_master/features/challenges/domain/local_date.dart';
import 'package:chess_master/features/challenges/domain/reward_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DeterministicChallengeGenerator generator =
      DeterministicChallengeGenerator();
  final LocalDate date = LocalDate.parse('2026-07-23');
  final DateTime now = DateTime(2026, 7, 23, 12);

  test('deduplicates progress and grants a completed reward once', () async {
    final InMemoryChallengeRepository repository =
        InMemoryChallengeRepository();
    final List<DailyChallenge> definitions = generator.generate(date);
    final DailyChallenge moveChallenge = definitions.singleWhere(
      (DailyChallenge value) => value.type == ChallengeType.playLegalMoves,
    );

    var dashboard = await repository.load(
      date: date,
      definitions: definitions,
      now: now,
    );
    expect(dashboard.wallet.coins, 50);
    expect(dashboard.wallet.hints, 1);

    for (int index = 0; index < 10; index++) {
      dashboard = await repository.recordEvent(
        date: date,
        definitions: definitions,
        event: ChallengeEvent(
          id: 'game-1:move-$index',
          type: ChallengeType.playLegalMoves,
        ),
        now: now.add(Duration(minutes: index)),
      );
    }
    dashboard = await repository.recordEvent(
      date: date,
      definitions: definitions,
      event: const ChallengeEvent(
        id: 'game-1:move-0',
        type: ChallengeType.playLegalMoves,
      ),
      now: now,
    );
    expect(
      dashboard.today
          .singleWhere((DailyChallenge value) => value.id == moveChallenge.id)
          .currentProgress,
      10,
    );

    final first = await repository.claim(
      date: date,
      definitions: definitions,
      challengeId: moveChallenge.id,
      now: now.add(const Duration(hours: 1)),
    );
    final second = await repository.claim(
      date: date,
      definitions: definitions,
      challengeId: moveChallenge.id,
      now: now.add(const Duration(hours: 1)),
    );

    expect(first.newlyClaimed, isTrue);
    expect(second.newlyClaimed, isFalse);
    expect(second.dashboard.wallet.coins, 70);
    expect(
      (await repository.readLedger()).where(
        (entry) =>
            entry.type == RewardTransactionType.challengeReward &&
            entry.source == 'challenge:${moveChallenge.id}',
      ),
      hasLength(1),
    );
    expect((await repository.verifyLedgerIntegrity()).isValid, isTrue);
  });

  test(
    'spends hints atomically, deduplicates requests, and never goes negative',
    () async {
      final InMemoryChallengeRepository repository =
          InMemoryChallengeRepository();
      await repository.load(
        date: date,
        definitions: generator.generate(date),
        now: now,
      );

      final first = await repository.purchaseHint(
        method: HintPaymentMethod.hint,
        requestId: 'request-1',
        now: now,
      );
      final duplicate = await repository.purchaseHint(
        method: HintPaymentMethod.hint,
        requestId: 'request-1',
        now: now,
      );

      expect(first.wallet.hints, 0);
      expect(duplicate.wallet.hints, 0);
      expect(duplicate.duplicate, isTrue);
      await expectLater(
        repository.purchaseHint(
          method: HintPaymentMethod.hint,
          requestId: 'request-2',
          now: now,
        ),
        throwsA(
          isA<EconomyFailure>().having(
            (EconomyFailure failure) => failure.code,
            'code',
            'insufficient_hints',
          ),
        ),
      );
    },
  );
}
