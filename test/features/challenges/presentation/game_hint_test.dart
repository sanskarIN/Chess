import 'package:chess_master/features/challenges/application/daily_challenges_controller.dart';
import 'package:chess_master/features/challenges/data/deterministic_challenge_generator.dart';
import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/daily_challenge.dart';
import 'package:chess_master/features/challenges/domain/hint_suggestion.dart';
import 'package:chess_master/features/challenges/domain/local_date.dart';
import 'package:chess_master/features/challenges/domain/reward_wallet.dart';
import 'package:chess_master/features/chess/application/game_setup.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/position.dart';
import 'package:chess_master/features/chess/presentation/game_screen.dart';
import 'package:chess_master/features/computer_player/application/engine_service.dart';
import 'package:chess_master/features/computer_player/domain/engine_configuration.dart';
import 'package:chess_master/features/computer_player/domain/engine_difficulty.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_chess_engine.dart';
import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('confirms cost, charges after success, and displays the hint', (
    WidgetTester tester,
  ) async {
    final InMemoryChallengeRepository repository =
        InMemoryChallengeRepository();
    final DailyChallengesController challenges = DailyChallengesController(
      repository: repository,
      generator: const DeterministicChallengeGenerator(),
      hintService: const _HintService(),
      now: () => DateTime(2026, 7, 23, 12),
    );
    final FakeChessEngine engine = FakeChessEngine(
      initialConfiguration: EngineConfiguration.forDifficulty(
        EngineDifficulty.beginner,
      ),
      selector: (_) => Move.fromUci('e7e5'),
    );
    final GameSetup setup = GameSetup.computer(
      playerName: 'Ada',
      defaultPlayerName: 'You',
      computerName: 'Computer',
      sideChoice: PlayerSideChoice.white,
      timeControl: TimeControl.none,
      difficulty: ComputerDifficulty.beginner,
      hintsEnabled: true,
    );

    await tester.pumpWidget(
      localizedTestApp(
        GameScreen(
          setup: setup,
          engineService: EngineService(ownedEngine: engine),
          challengesController: challenges,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final Finder hint = find.byTooltip('Hint');
    await tester.ensureVisible(hint);
    await tester.tap(hint);
    await tester.pump();

    expect(find.text('Use a hint?'), findsOneWidget);
    expect(find.textContaining('charged only after'), findsOneWidget);
    await tester.tap(find.text('Use 1 hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Suggested move: E2 to E4'), findsWidgets);
    expect(find.textContaining('strong candidate'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey<String>('square-e2')))
          .properties
          .label,
      contains('hint source'),
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey<String>('square-e4')))
          .properties
          .label,
      contains('hint target'),
    );
    expect(challenges.dashboard!.wallet.hints, 0);
    expect(
      (await repository.readLedger()).where(
        (entry) => entry.type == RewardTransactionType.hintPurchase,
      ),
      hasLength(1),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('records legal moves and completed local matches once', (
    WidgetTester tester,
  ) async {
    const DeterministicChallengeGenerator generator =
        DeterministicChallengeGenerator();
    DateTime challengeDate = DateTime(2026, 1, 1, 12);
    while (true) {
      final Set<ChallengeType> types = generator
          .generate(LocalDate.fromLocal(challengeDate))
          .map((DailyChallenge challenge) => challenge.type)
          .toSet();
      if (types.contains(ChallengeType.finishMatch) &&
          types.contains(ChallengeType.localMatch)) {
        break;
      }
      challengeDate = challengeDate.add(const Duration(days: 1));
    }
    final DailyChallengesController challenges = DailyChallengesController(
      repository: InMemoryChallengeRepository(),
      generator: generator,
      hintService: const _HintService(),
      now: () => challengeDate,
    );
    final GameSetup setup = GameSetup.local(
      playerOneName: 'Ada',
      playerTwoName: 'Grace',
      defaultPlayerOneName: 'Player 1',
      defaultPlayerTwoName: 'Player 2',
      playerOneSide: PlayerSideChoice.white,
      timeControl: TimeControl.none,
    );

    await tester.pumpWidget(
      localizedTestApp(
        GameScreen(setup: setup, challengesController: challenges),
      ),
    );
    await tester.pump();
    await _play(tester, 'f2', 'f3');
    await _play(tester, 'e7', 'e5');
    await _play(tester, 'g2', 'g4');
    await _play(tester, 'd8', 'h4');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final Map<ChallengeType, DailyChallenge> byType =
        <ChallengeType, DailyChallenge>{
          for (final DailyChallenge challenge in challenges.dashboard!.today)
            challenge.type: challenge,
        };
    expect(byType[ChallengeType.playLegalMoves]!.currentProgress, 4);
    expect(byType[ChallengeType.finishMatch]!.isCompleted, isTrue);
    expect(byType[ChallengeType.localMatch]!.isCompleted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _play(WidgetTester tester, String from, String to) async {
  final Finder fromSquare = find.byKey(ValueKey<String>('square-$from'));
  final Finder toSquare = find.byKey(ValueKey<String>('square-$to'));
  await tester.ensureVisible(fromSquare);
  await tester.tap(fromSquare);
  await tester.pump();
  await tester.ensureVisible(toSquare);
  await tester.tap(toSquare);
  await tester.pump();
}

final class _HintService implements HintService {
  const _HintService();

  @override
  Future<HintSuggestion> generate(Position position) async {
    return HintSuggestion(
      move: Move.fromUci('e2e4'),
      explanationKey: 'hintExplanationCandidate',
    );
  }
}
