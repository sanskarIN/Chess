import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/practice_providers.dart';
import '../data/tutorial_catalog.dart';
import '../domain/learning_progress.dart';
import '../domain/tutorial_lesson.dart';
import 'practice_launch.dart';
import 'practice_localizations.dart';

final class TutorialScreen extends ConsumerWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AsyncValue<Map<String, TutorialLessonProgress>> progress = ref.watch(
      tutorialProgressProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(strings.tutorial)),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => ref.invalidate(tutorialProgressProvider),
              icon: const Icon(Icons.refresh),
              label: Text(strings.retry),
            ),
          );
        },
        data: (Map<String, TutorialLessonProgress> values) {
          final int completed = values.values
              .where((TutorialLessonProgress item) => item.isCompleted)
              .length;
          return ListView(
            padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        strings.tutorialDescription,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: DesignTokens.space12),
                      LinearProgressIndicator(
                        value: completed / TutorialCatalog.lessons.length,
                      ),
                      const SizedBox(height: DesignTokens.space8),
                      Text(
                        strings.lessonCountProgress(
                          completed,
                          TutorialCatalog.lessons.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space12),
              for (
                int index = 0;
                index < TutorialCatalog.lessons.length;
                index++
              )
                _LessonTile(
                  index: index,
                  lesson: TutorialCatalog.lessons[index],
                  progress: values[TutorialCatalog.lessons[index].id],
                ),
            ],
          );
        },
      ),
    );
  }
}

final class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.progress,
  });

  final int index;
  final TutorialLesson lesson;
  final TutorialLessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool completed = progress?.isCompleted ?? false;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: completed ? const Icon(Icons.check) : Text('${index + 1}'),
        ),
        title: Text(tutorialTitle(strings, lesson.topic)),
        subtitle: Text(tutorialObjective(strings, lesson.topic)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          AppRoutes.tutorialLesson,
          extra: TutorialLessonLaunch(lesson: lesson),
        ),
      ),
    );
  }
}
