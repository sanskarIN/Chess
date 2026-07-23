import 'package:chess_master/app/app_theme.dart';
import 'package:chess_master/features/challenges/application/challenge_providers.dart';
import 'package:chess_master/features/challenges/application/daily_challenges_controller.dart';
import 'package:chess_master/features/challenges/data/deterministic_challenge_generator.dart';
import 'package:chess_master/features/challenges/data/in_memory_challenge_repository.dart';
import 'package:chess_master/features/challenges/domain/challenge_event.dart';
import 'package:chess_master/features/challenges/domain/daily_challenge.dart';
import 'package:chess_master/features/challenges/domain/hint_suggestion.dart';
import 'package:chess_master/features/challenges/presentation/daily_challenges_screen.dart';
import 'package:chess_master/features/chess/domain/model/move.dart';
import 'package:chess_master/features/chess/domain/model/position.dart';
import 'package:chess_master/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows balances, progress, one-time claim, and offline limits', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 7, 23, 12);
    final DailyChallengesController controller = DailyChallengesController(
      repository: InMemoryChallengeRepository(),
      generator: const DeterministicChallengeGenerator(),
      hintService: const _HintService(),
      now: () => now,
    );
    await controller.initialize();
    for (int index = 0; index < 10; index++) {
      await controller.recordEvent(
        ChallengeEvent(
          id: 'widget-move-$index',
          type: ChallengeType.playLegalMoves,
        ),
      );
    }

    await tester.pumpWidget(_testApp(controller));
    await tester.pump();

    expect(find.text('50 Coins'), findsOneWidget);
    expect(find.text('1 Hints'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Opening rhythm'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Opening rhythm'), findsOneWidget);
    expect(find.text('10/10'), findsOneWidget);

    final Finder claim = find.widgetWithText(FilledButton, 'Claim');
    await tester.ensureVisible(claim);
    await tester.tap(claim);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Claimed'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('70 Coins'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('70 Coins'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('not tamper-proof'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('not tamper-proof'), findsOneWidget);
    expect(
      (await controller.readLedger()).where(
        (entry) => entry.source.contains('playLegalMoves'),
      ),
      hasLength(1),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _testApp(DailyChallengesController controller) {
  return ProviderScope(
    overrides: [
      dailyChallengesControllerProvider.overrideWith((Ref ref) => controller),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DailyChallengesScreen(),
    ),
  );
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
