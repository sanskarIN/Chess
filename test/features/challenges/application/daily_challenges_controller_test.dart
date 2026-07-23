import 'package:chess_master/features/challenges/application/daily_challenges_controller.dart';
import 'package:chess_master/features/challenges/data/deterministic_challenge_generator.dart';
import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/hint_suggestion.dart';
import 'package:chess_master/features/challenges/domain/local_date.dart';
import 'package:chess_master/features/challenges/domain/reward_wallet.dart';
import 'package:chess_master/features/chess/domain/model/chess_game.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 23, 12);

  test('simulates another date without changing the supplied clock', () async {
    final DailyChallengesController controller = DailyChallengesController(
      repository: InMemoryChallengeRepository(),
      generator: const DeterministicChallengeGenerator(),
      hintService: const _SuccessfulHintService(),
      now: () => now,
    );
    await controller.initialize();
    expect(controller.dashboard!.date.value, '2026-07-23');

    await controller.simulateDate(LocalDate.parse('2027-01-02'));

    expect(controller.dashboard!.date.value, '2027-01-02');
    expect(now, DateTime(2026, 7, 23, 12));
    expect(controller.dashboard!.history, isNotEmpty);
  });

  test('does not charge when local hint generation fails', () async {
    final InMemoryChallengeRepository repository =
        InMemoryChallengeRepository();
    final DailyChallengesController controller = DailyChallengesController(
      repository: repository,
      generator: const DeterministicChallengeGenerator(),
      hintService: const _FailingHintService(),
      now: () => now,
    );
    await controller.initialize();
    final RewardWallet before = controller.dashboard!.wallet;

    await expectLater(
      controller.requestHint(
        position: ChessGame(gameId: 'hint-test').position,
        paymentMethod: HintPaymentMethod.coins,
        requestId: 'failed-request',
      ),
      throwsStateError,
    );

    expect(controller.dashboard!.wallet.coins, before.coins);
    expect(
      (await repository.readLedger()).where(
        (entry) => entry.type == RewardTransactionType.hintPurchase,
      ),
      isEmpty,
    );
  });

  test('charges exactly once only after a usable hint exists', () async {
    final InMemoryChallengeRepository repository =
        InMemoryChallengeRepository();
    final DailyChallengesController controller = DailyChallengesController(
      repository: repository,
      generator: const DeterministicChallengeGenerator(),
      hintService: const _SuccessfulHintService(),
      now: () => now,
    );
    await controller.initialize();

    final first = await controller.requestHint(
      position: ChessGame(gameId: 'hint-test').position,
      paymentMethod: HintPaymentMethod.coins,
      requestId: 'successful-request',
    );
    final second = await controller.requestHint(
      position: ChessGame(gameId: 'hint-test').position,
      paymentMethod: HintPaymentMethod.coins,
      requestId: 'successful-request',
    );

    expect(first.suggestion.move.uci, 'e2e4');
    expect(first.purchase.wallet.coins, 25);
    expect(second.purchase.duplicate, isTrue);
    expect(second.purchase.wallet.coins, 25);
  });
}

final class _SuccessfulHintService implements HintService {
  const _SuccessfulHintService();

  @override
  Future<HintSuggestion> generate(Position position) async {
    return HintSuggestion(
      move: Move.fromUci('e2e4'),
      explanationKey: 'hintExplanationCandidate',
    );
  }
}

final class _FailingHintService implements HintService {
  const _FailingHintService();

  @override
  Future<HintSuggestion> generate(Position position) {
    throw StateError('No hint available.');
  }
}
