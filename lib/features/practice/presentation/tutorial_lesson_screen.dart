import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../challenges/application/challenge_providers.dart';
import '../../chess/presentation/widgets/chess_board.dart';
import '../application/practice_providers.dart';
import '../application/tutorial_lesson_controller.dart';
import '../domain/tutorial_lesson.dart';
import 'practice_localizations.dart';

final class TutorialLessonScreen extends ConsumerStatefulWidget {
  const TutorialLessonScreen({required this.lesson, super.key});

  final TutorialLesson lesson;

  @override
  ConsumerState<TutorialLessonScreen> createState() =>
      _TutorialLessonScreenState();
}

final class _TutorialLessonScreenState
    extends ConsumerState<TutorialLessonScreen> {
  late final TutorialLessonController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TutorialLessonController(
      lesson: widget.lesson,
      progressRepository: ref.read(learningProgressRepositoryProvider),
      challengeRepository: ref.read(challengeRepositoryProvider),
    )..addListener(_handleChanged);
    unawaited(_controller.initialize());
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tutorialTitle(strings, widget.lesson.topic))),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget board = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ChessBoard(
                position: _controller.position,
                selectedSquare: _controller.selectedSquare,
                legalMoves: _controller.legalMovesForSelection,
                lastMove: _controller.lastMove,
                checkedKingSquare: _controller.checkedKingSquare,
                flipped: false,
                enabled: !_controller.busy && !_controller.success,
                onSquareTap: (square) {
                  unawaited(_controller.selectSquare(square));
                },
              ),
            );
            final Widget lesson = _LessonPanel(
              controller: _controller,
              lesson: widget.lesson,
            );
            if (constraints.maxWidth >= 900) {
              return SingleChildScrollView(
                padding: DesignTokens.pagePadding(constraints.maxWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: board),
                    const SizedBox(width: DesignTokens.space24),
                    Expanded(flex: 2, child: lesson),
                  ],
                ),
              );
            }
            return ListView(
              padding: DesignTokens.pagePadding(constraints.maxWidth),
              children: <Widget>[
                lesson,
                const SizedBox(height: DesignTokens.space16),
                board,
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _LessonPanel extends StatelessWidget {
  const _LessonPanel({required this.controller, required this.lesson});

  final TutorialLessonController controller;
  final TutorialLesson lesson;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.objective,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  tutorialObjective(strings, lesson.topic),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: DesignTokens.space16),
                Text(
                  strings.instructions,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(tutorialInstructions(strings, lesson.topic)),
              ],
            ),
          ),
        ),
        if (controller.errorCode != null)
          Card(
            color: colors.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space12),
              child: Text(
                strings.tryAgain,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ),
        if (controller.success)
          Card(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.lessonSuccess,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    controller.newReward
                        ? strings.firstRewardCoins(lesson.rewardCoins)
                        : strings.rewardAlreadyEarned,
                  ),
                  const SizedBox(height: DesignTokens.space12),
                  OutlinedButton.icon(
                    onPressed: controller.retry,
                    icon: const Icon(Icons.replay),
                    label: Text(strings.retry),
                  ),
                ],
              ),
            ),
          ),
        if (controller.progress case final progress?)
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space8),
            child: Text(strings.attemptsCount(progress.attempts)),
          ),
        if (controller.busy) const LinearProgressIndicator(),
      ],
    );
  }
}
