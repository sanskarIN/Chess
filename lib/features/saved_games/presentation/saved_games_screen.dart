import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/domain/notation/pgn_codec.dart';
import '../application/saved_game_providers.dart';
import '../data/saved_game_repository.dart';
import '../domain/saved_game.dart';

final class SavedGamesScreen extends ConsumerWidget {
  const SavedGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AsyncValue<List<SavedGame>> savedGames = ref.watch(
      savedGamesProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(strings.savedGamesTitle)),
      body: savedGames.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(savedGamesProvider),
            icon: const Icon(Icons.refresh),
            label: Text(strings.retry),
          ),
        ),
        data: (List<SavedGame> values) {
          return ListView(
            padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
            children: <Widget>[
              Text(
                strings.savedGamesSubtitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignTokens.space16),
              Wrap(
                spacing: DesignTokens.space8,
                runSpacing: DesignTokens.space8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => _import(context, ref, fen: true),
                    icon: const Icon(Icons.data_object),
                    label: Text(strings.importFen),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _import(context, ref, fen: false),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(strings.importPgn),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space16),
              if (values.isEmpty)
                _EmptySavedGames(strings: strings)
              else
                for (final SavedGame savedGame in values)
                  _SavedGameCard(savedGame: savedGame),
            ],
          );
        },
      ),
    );
  }

  Future<void> _import(
    BuildContext context,
    WidgetRef ref, {
    required bool fen,
  }) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController titleController = TextEditingController(
      text: strings.defaultSaveTitle,
    );
    final TextEditingController sourceController = TextEditingController();
    bool failed = false;
    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext dialogContext,
                void Function(VoidCallback) setDialogState,
              ) {
                return AlertDialog(
                  title: Text(fen ? strings.importFen : strings.importPgn),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextField(
                            controller: titleController,
                            maxLength: 80,
                            decoration: InputDecoration(
                              labelText: strings.importTitle,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space12),
                          TextField(
                            controller: sourceController,
                            minLines: 5,
                            maxLines: 12,
                            decoration: InputDecoration(
                              labelText: strings.importText,
                              errorText: failed ? strings.importFailed : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(strings.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) {
                          setDialogState(() => failed = true);
                          return;
                        }
                        Navigator.of(dialogContext).pop(true);
                      },
                      child: Text(strings.importGame),
                    ),
                  ],
                );
              },
        );
      },
    );
    if (submit != true) {
      titleController.dispose();
      sourceController.dispose();
      return;
    }
    try {
      final SavedGameRepository repository = ref.read(
        savedGameRepositoryProvider,
      );
      if (fen) {
        await repository.importFen(
          fen: sourceController.text,
          title: titleController.text,
          now: DateTime.now().toUtc(),
        );
      } else {
        await repository.importPgn(
          pgn: sourceController.text,
          title: titleController.text,
          now: DateTime.now().toUtc(),
        );
      }
      ref.invalidate(savedGamesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.importSucceeded)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.importFailed)));
      }
    } finally {
      titleController.dispose();
      sourceController.dispose();
    }
  }
}

final class _EmptySavedGames extends StatelessWidget {
  const _EmptySavedGames({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space32),
        child: Column(
          children: <Widget>[
            const Icon(Icons.bookmark_border, size: 48),
            const SizedBox(height: DesignTokens.space12),
            Text(
              strings.noSavedGames,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(strings.noSavedGamesDescription, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _SavedGameCard extends ConsumerWidget {
  const _SavedGameCard({required this.savedGame});

  final SavedGame savedGame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              child: Icon(
                savedGame.isCompleted
                    ? Icons.emoji_events_outlined
                    : Icons.bookmark_outline,
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    savedGame.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${savedGame.setup.whitePlayerName} · '
                    '${savedGame.setup.blackPlayerName} · '
                    '${savedGame.game.moveRecords.length}',
                  ),
                ],
              ),
            ),
            PopupMenuButton<_SavedAction>(
              onSelected: (_SavedAction action) {
                _perform(context, ref, action);
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<_SavedAction>>[
                    PopupMenuItem(
                      value: _SavedAction.resume,
                      child: Text(strings.resumeGame),
                    ),
                    PopupMenuItem(
                      value: _SavedAction.review,
                      child: Text(strings.reviewGame),
                    ),
                    PopupMenuItem(
                      value: _SavedAction.rename,
                      child: Text(strings.rename),
                    ),
                    PopupMenuItem(
                      value: _SavedAction.copyFen,
                      child: Text(strings.copyFen),
                    ),
                    PopupMenuItem(
                      value: _SavedAction.copyPgn,
                      child: Text(strings.exportPgn),
                    ),
                    PopupMenuItem(
                      value: _SavedAction.delete,
                      child: Text(strings.delete),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    _SavedAction action,
  ) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    switch (action) {
      case _SavedAction.resume:
        await context.push(
          AppRoutes.savedGame,
          extra: SavedGameLaunch(savedGame: savedGame),
        );
        return;
      case _SavedAction.review:
        await context.push(
          AppRoutes.review,
          extra: ReviewLaunch(
            game: savedGame.game,
            setup: savedGame.setup,
            savedGameId: savedGame.id,
          ),
        );
        return;
      case _SavedAction.copyFen:
        await Clipboard.setData(
          ClipboardData(text: FenCodec.encode(savedGame.game.position)),
        );
        if (context.mounted) {
          _message(context, strings.fenCopied);
        }
        return;
      case _SavedAction.copyPgn:
        await Clipboard.setData(
          ClipboardData(
            text: const PgnCodec().encode(
              savedGame.game,
              tags: <String, String>{
                'White': savedGame.setup.whitePlayerName,
                'Black': savedGame.setup.blackPlayerName,
              },
            ),
          ),
        );
        if (context.mounted) {
          _message(context, strings.pgnCopied);
        }
        return;
      case _SavedAction.rename:
        final String? title = await _askForTitle(
          context,
          initial: savedGame.title,
        );
        if (title != null) {
          await ref
              .read(savedGameRepositoryProvider)
              .rename(
                savedGameId: savedGame.id,
                title: title,
                now: DateTime.now().toUtc(),
              );
          ref.invalidate(savedGamesProvider);
        }
        return;
      case _SavedAction.delete:
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(strings.deleteSavedGameTitle),
            content: Text(strings.deleteSavedGameDescription),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.delete),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(savedGameRepositoryProvider).delete(savedGame.id);
          ref.invalidate(savedGamesProvider);
          if (context.mounted) {
            _message(context, strings.savedGameDeleted);
          }
        }
        return;
    }
  }

  Future<String?> _askForTitle(
    BuildContext context, {
    required String initial,
  }) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController(
      text: initial,
    );
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(strings.rename),
        content: TextField(
          controller: controller,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: strings.saveTitle,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final String value = controller.text.trim();
              if (value.isNotEmpty && value.length <= 80) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Text(strings.rename),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _SavedAction { resume, review, rename, copyFen, copyPgn, delete }
