import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/domain/model/position.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../domain/training_puzzle.dart';
import 'practice_launch.dart';

final class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<_PracticeDestination> destinations = <_PracticeDestination>[
      _PracticeDestination(
        icon: Icons.school_outlined,
        title: strings.tutorial,
        description: strings.tutorialDescription,
        onTap: () => context.push(AppRoutes.tutorial),
      ),
      _PracticeDestination(
        icon: Icons.extension_outlined,
        title: strings.puzzles,
        description: strings.puzzlesDescription,
        onTap: () =>
            context.push(AppRoutes.puzzles, extra: const PuzzleListLaunch()),
      ),
      _PracticeDestination(
        icon: Icons.dashboard_customize_outlined,
        title: strings.freeBoard,
        description: strings.freeBoardDescription,
        onTap: () => context.push(
          AppRoutes.practiceBoard,
          extra: const PracticeBoardLaunch(),
        ),
      ),
      _PracticeDestination(
        icon: Icons.route_outlined,
        title: strings.pieceMovementGuide,
        description: strings.pieceMovementGuideDescription,
        onTap: () => context.push(AppRoutes.tutorial),
      ),
      _PracticeDestination(
        icon: Icons.check_circle_outline,
        title: strings.legalMovePractice,
        description: strings.legalMovePracticeDescription,
        onTap: () => context.push(
          AppRoutes.practiceBoard,
          extra: const PracticeBoardLaunch(),
        ),
      ),
      _PracticeDestination(
        icon: Icons.filter_1_outlined,
        title: strings.mateInOne,
        description: strings.puzzlesDescription,
        onTap: () => _openPuzzles(context, TrainingPuzzleType.mateInOne),
      ),
      _PracticeDestination(
        icon: Icons.filter_2_outlined,
        title: strings.mateInTwo,
        description: strings.puzzlesDescription,
        onTap: () => _openPuzzles(context, TrainingPuzzleType.mateInTwo),
      ),
      _PracticeDestination(
        icon: Icons.bolt_outlined,
        title: strings.tactics,
        description: strings.puzzlesDescription,
        onTap: () => _openPuzzles(context, TrainingPuzzleType.tactic),
      ),
      _PracticeDestination(
        icon: Icons.auto_stories_outlined,
        title: strings.openings,
        description: strings.puzzlesDescription,
        onTap: () => _openPuzzles(context, TrainingPuzzleType.opening),
      ),
      _PracticeDestination(
        icon: Icons.flag_outlined,
        title: strings.endgames,
        description: strings.puzzlesDescription,
        onTap: () => _openPuzzles(context, TrainingPuzzleType.endgame),
      ),
      _PracticeDestination(
        icon: Icons.data_object,
        title: strings.customFen,
        description: strings.customFenDescription,
        onTap: () => _showFenDialog(context),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(strings.practiceTitle)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            return ListView(
              padding: DesignTokens.pagePadding(constraints.maxWidth),
              children: <Widget>[
                Text(
                  strings.practiceSubtitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DesignTokens.space20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: DesignTokens.space12,
                    mainAxisSpacing: DesignTokens.space12,
                    childAspectRatio: columns == 1 ? 2.5 : 1.45,
                  ),
                  itemCount: destinations.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _PracticeCard(destination: destinations[index]);
                  },
                ),
                const SizedBox(height: DesignTokens.space32),
                const CreatorWatermark(),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openPuzzles(BuildContext context, TrainingPuzzleType type) {
    context.push(AppRoutes.puzzles, extra: PuzzleListLaunch(type: type));
  }

  Future<void> _showFenDialog(BuildContext context) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController(
      text: FenCodec.standardInitialPosition,
    );
    String? error;
    final PositionResult? result = await showDialog<PositionResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext dialogContext,
                void Function(VoidCallback) setDialogState,
              ) {
                return AlertDialog(
                  title: Text(strings.customFen),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: strings.enterFen,
                        errorText: error,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(strings.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        try {
                          final position = FenCodec.decode(controller.text);
                          Navigator.of(
                            dialogContext,
                          ).pop(PositionResult(position));
                        } on FormatException {
                          setDialogState(() => error = strings.invalidFen);
                        } on StateError {
                          setDialogState(() => error = strings.invalidFen);
                        }
                      },
                      child: Text(strings.loadPosition),
                    ),
                  ],
                );
              },
        );
      },
    );
    controller.dispose();
    if (result != null && context.mounted) {
      await context.push(
        AppRoutes.practiceBoard,
        extra: PracticeBoardLaunch(initialPosition: result.position),
      );
    }
  }
}

final class PositionResult {
  const PositionResult(this.position);

  final Position position;
}

final class _PracticeDestination {
  const _PracticeDestination({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
}

final class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.destination});

  final _PracticeDestination destination;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: destination.onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                destination.icon,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              const SizedBox(height: DesignTokens.space8),
              Text(
                destination.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DesignTokens.space4),
              Expanded(
                child: Text(
                  destination.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
