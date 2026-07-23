import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../challenges/application/challenge_providers.dart';
import '../../chess/presentation/widgets/chess_board.dart';
import '../application/practice_providers.dart';
import '../application/puzzle_controller.dart';
import '../domain/training_puzzle.dart';
import 'practice_localizations.dart';

final class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({required this.puzzle, super.key});

  final TrainingPuzzle puzzle;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

final class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  late final PuzzleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PuzzleController(
      puzzle: widget.puzzle,
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
    final Widget details = _PuzzleDetails(
      controller: _controller,
      puzzle: widget.puzzle,
    );
    return Scaffold(
      appBar: AppBar(title: Text(puzzleTitle(strings, widget.puzzle))),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= 900) {
            return SingleChildScrollView(
              padding: DesignTokens.pagePadding(constraints.maxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: board),
                  const SizedBox(width: DesignTokens.space24),
                  Expanded(flex: 2, child: details),
                ],
              ),
            );
          }
          return ListView(
            padding: DesignTokens.pagePadding(constraints.maxWidth),
            children: <Widget>[
              details,
              const SizedBox(height: DesignTokens.space16),
              board,
            ],
          );
        },
      ),
    );
  }
}

final class _PuzzleDetails extends StatelessWidget {
  const _PuzzleDetails({required this.controller, required this.puzzle});

  final PuzzleController controller;
  final TrainingPuzzle puzzle;

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
                  puzzleTypeLabel(strings, puzzle.type),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  puzzleDescription(strings, puzzle),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DesignTokens.space12),
                Text(
                  strings.puzzleLineProgress(
                    controller.completedPlies,
                    puzzle.solution.length,
                  ),
                ),
                LinearProgressIndicator(
                  value: controller.completedPlies / puzzle.solution.length,
                ),
              ],
            ),
          ),
        ),
        if (controller.errorCode != null)
          Card(
            color: colors.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space12),
              child: Text(strings.tryAgain),
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
                    strings.puzzleSuccess,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space8),
                  Text(
                    controller.newReward
                        ? strings.firstRewardCoins(10)
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
