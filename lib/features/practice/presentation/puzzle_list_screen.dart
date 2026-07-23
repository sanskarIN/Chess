import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/practice_providers.dart';
import '../domain/learning_progress.dart';
import '../domain/training_puzzle.dart';
import 'practice_launch.dart';
import 'practice_localizations.dart';

final class PuzzleListScreen extends ConsumerWidget {
  const PuzzleListScreen({this.type, super.key});

  final TrainingPuzzleType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AsyncValue<List<TrainingPuzzle>> puzzles = ref.watch(
      trainingPuzzlesProvider,
    );
    final AsyncValue<Map<String, PracticeExerciseProgress>> progress = ref
        .watch(practiceProgressProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          type == null ? strings.puzzles : puzzleTypeLabel(strings, type!),
        ),
      ),
      body: puzzles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(strings.puzzleCatalogFailed),
                const SizedBox(height: DesignTokens.space12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(trainingPuzzlesProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.retry),
                ),
              ],
            ),
          ),
        ),
        data: (List<TrainingPuzzle> values) {
          final List<TrainingPuzzle> visible = values
              .where(
                (TrainingPuzzle puzzle) => type == null || puzzle.type == type,
              )
              .toList(growable: false);
          if (visible.isEmpty) {
            return Center(child: Text(strings.noPuzzles));
          }
          final Map<String, PracticeExerciseProgress> progressValues =
              progress.value ?? const <String, PracticeExerciseProgress>{};
          return ListView.builder(
            padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) {
              final TrainingPuzzle puzzle = visible[index];
              final bool solved = progressValues[puzzle.id]?.isSolved ?? false;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: solved
                        ? const Icon(Icons.check)
                        : const Icon(Icons.extension_outlined),
                  ),
                  title: Text(puzzleTitle(strings, puzzle)),
                  subtitle: Text(
                    '${puzzleTypeLabel(strings, puzzle.type)} · '
                    '${puzzle.difficulty.name}\n'
                    '${puzzleDescription(strings, puzzle)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.puzzle,
                    extra: PuzzleLaunch(puzzle: puzzle),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
