import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/locale_formatting.dart';
import '../../../l10n/supported_locales.dart';
import '../../chess/application/game_setup.dart';
import '../../chess/domain/model/piece_color.dart';
import '../../saved_games/domain/saved_game.dart';
import '../application/match_history_providers.dart';
import '../domain/match_history.dart';

final class HistoryStatisticsScreen extends ConsumerWidget {
  const HistoryStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.historyStatisticsTitle),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(icon: const Icon(Icons.history), text: strings.historyTab),
              Tab(
                icon: const Icon(Icons.query_stats),
                text: strings.statisticsTab,
              ),
              Tab(
                icon: const Icon(Icons.emoji_events_outlined),
                text: strings.achievementsTab,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _HistoryTab(),
            _StatisticsTab(),
            _AchievementsTab(),
          ],
        ),
      ),
    );
  }
}

final class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final MatchHistoryFilter selected = ref.watch(matchHistoryFilterProvider);
    final AsyncValue<List<MatchHistoryEntry>> history = ref.watch(
      matchHistoryProvider,
    );
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchHistoryProvider);
        await ref.read(matchHistoryProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        children: <Widget>[
          Text(
            strings.historyPrivacyNotice,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: DesignTokens.space16),
          DropdownButtonFormField<MatchHistoryFilter>(
            initialValue: selected,
            decoration: InputDecoration(
              labelText: strings.filterLabel,
              prefixIcon: const Icon(Icons.filter_list),
            ),
            items: <DropdownMenuItem<MatchHistoryFilter>>[
              for (final MatchHistoryFilter filter in MatchHistoryFilter.values)
                DropdownMenuItem<MatchHistoryFilter>(
                  value: filter,
                  child: Text(_filterLabel(strings, filter)),
                ),
            ],
            onChanged: (MatchHistoryFilter? filter) {
              if (filter != null) {
                ref.read(matchHistoryFilterProvider.notifier).select(filter);
              }
            },
          ),
          const SizedBox(height: DesignTokens.space16),
          history.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) =>
                _RetryCard(onRetry: () => ref.invalidate(matchHistoryProvider)),
            data: (List<MatchHistoryEntry> entries) {
              if (entries.isEmpty) {
                return _EmptyCard(
                  message: selected == MatchHistoryFilter.all
                      ? strings.noMatchHistory
                      : strings.noFilteredMatches,
                );
              }
              return Column(
                children: <Widget>[
                  for (final MatchHistoryEntry entry in entries) ...<Widget>[
                    _HistoryCard(entry: entry),
                    const SizedBox(height: DesignTokens.space12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _filterLabel(AppLocalizations strings, MatchHistoryFilter filter) {
    return switch (filter) {
      MatchHistoryFilter.all => strings.filterAll,
      MatchHistoryFilter.wins => strings.filterWins,
      MatchHistoryFilter.losses => strings.filterLosses,
      MatchHistoryFilter.draws => strings.filterDraws,
      MatchHistoryFilter.computer => strings.filterComputer,
      MatchHistoryFilter.local => strings.filterLocal,
      MatchHistoryFilter.friend => strings.filterFriend,
      MatchHistoryFilter.white => strings.filterWhite,
      MatchHistoryFilter.black => strings.filterBlack,
      MatchHistoryFilter.beginner => strings.beginner,
      MatchHistoryFilter.intermediate => strings.intermediate,
      MatchHistoryFilter.expert => strings.expert,
      MatchHistoryFilter.grandmaster => strings.grandmaster,
    };
  }
}

final class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final MatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final LocaleFormatting formatting = _formatting(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (IconData, Color) outcomeVisual = switch (entry.outcome) {
      MatchOutcome.win => (Icons.emoji_events, colors.primary),
      MatchOutcome.loss => (Icons.close, colors.error),
      MatchOutcome.draw => (Icons.handshake_outlined, colors.tertiary),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label:
            '${_outcomeLabel(strings, entry.outcome)}, '
            '${strings.opponentLabel}: ${entry.opponentName}',
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.review,
            extra: ReviewLaunch(game: entry.game, setup: entry.setup),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      outcomeVisual.$1,
                      color: outcomeVisual.$2,
                      semanticLabel: _outcomeLabel(strings, entry.outcome),
                    ),
                    const SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _outcomeLabel(strings, entry.outcome),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_modeLabel(strings, entry.mode)} · '
                            '${entry.playerColor == PieceColor.white ? strings.white : strings.black}',
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const Divider(height: DesignTokens.space24),
                _DetailLine(
                  label: strings.opponentLabel,
                  value: entry.opponentName,
                ),
                _DetailLine(
                  label: strings.completedLabel,
                  value: formatting.formatDate(entry.completedAt.toLocal()),
                ),
                _DetailLine(
                  label: strings.duration,
                  value: formatting.formatDuration(entry.duration),
                ),
                _DetailLine(
                  label: strings.moves,
                  value: formatting.formatInteger(entry.moveCount),
                ),
                _DetailLine(
                  label: strings.timeControl,
                  value: entry.timeControl.id,
                ),
                if (entry.mode == GameMode.computer)
                  _DetailLine(
                    label: strings.difficulty,
                    value: _difficultyLabel(strings, entry.difficulty),
                  ),
                _DetailLine(
                  label: strings.hintsUsed,
                  value: formatting.formatInteger(entry.hintCount),
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  strings.reviewHistoryGame,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatisticsTab extends ConsumerWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AsyncValue<ChessStatistics> statistics = ref.watch(
      chessStatisticsProvider,
    );
    return statistics.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: _RetryCard(
          onRetry: () => ref.invalidate(chessStatisticsProvider),
        ),
      ),
      data: (ChessStatistics value) {
        final LocaleFormatting formatting = _formatting(context);
        final List<(String, String)> rows = <(String, String)>[
          (
            strings.gamesPlayedStatistic,
            formatting.formatInteger(value.gamesPlayed),
          ),
          (strings.winsStatistic, formatting.formatInteger(value.wins)),
          (strings.lossesStatistic, formatting.formatInteger(value.losses)),
          (strings.drawsStatistic, formatting.formatInteger(value.draws)),
          (
            strings.whiteResultsStatistic,
            strings.resultTriple(
              value.whiteWins,
              value.whiteLosses,
              value.whiteDraws,
            ),
          ),
          (
            strings.blackResultsStatistic,
            strings.resultTriple(
              value.blackWins,
              value.blackLosses,
              value.blackDraws,
            ),
          ),
          (
            strings.averageGameLengthStatistic,
            formatting.formatDuration(value.averageGameLength),
          ),
          (
            strings.fastestWinStatistic,
            value.fastestWin == null
                ? strings.notRecorded
                : formatting.formatDuration(value.fastestWin!),
          ),
          (
            strings.longestGameStatistic,
            value.longestGame == null
                ? strings.notRecorded
                : formatting.formatDuration(value.longestGame!),
          ),
          (
            strings.totalMovesStatistic,
            formatting.formatInteger(value.totalMoves),
          ),
          (
            strings.totalCapturesStatistic,
            formatting.formatInteger(value.totalCaptures),
          ),
          (
            strings.totalHintsUsedStatistic,
            formatting.formatInteger(value.totalHintsUsed),
          ),
          (
            strings.challengesCompletedStatistic,
            formatting.formatInteger(value.challengesCompleted),
          ),
          (
            strings.coinsEarnedStatistic,
            formatting.formatInteger(value.coinsEarned),
          ),
          (
            strings.hintsEarnedStatistic,
            formatting.formatInteger(value.hintsEarned),
          ),
          (
            strings.puzzlesSolvedStatistic,
            formatting.formatInteger(value.puzzlesSolved),
          ),
          (
            strings.currentStreakStatistic,
            formatting.formatInteger(value.currentStreak),
          ),
          (
            strings.bestStreakStatistic,
            formatting.formatInteger(value.bestStreak),
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(DesignTokens.space16),
          children: <Widget>[
            for (final MapEntry<ComputerDifficulty, int> win
                in value.computerWinsByDifficulty.entries)
              _StatisticTile(
                label:
                    '${strings.computerWinsByDifficultyStatistic} · '
                    '${_difficultyLabel(strings, win.key)}',
                value: formatting.formatInteger(win.value),
              ),
            for (final (String, String) row in rows)
              _StatisticTile(label: row.$1, value: row.$2),
            const SizedBox(height: DesignTokens.space16),
            OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text(strings.resetStatistics),
              onPressed: () => _confirmReset(context, ref),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(strings.resetStatisticsTitle),
        content: Text(strings.resetStatisticsDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.resetStatistics),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref
        .read(matchHistoryRepositoryProvider)
        .resetStatistics(DateTime.now());
    ref.invalidate(chessStatisticsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(strings.statisticsResetCompleted)),
        );
    }
  }
}

final class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AsyncValue<List<AchievementProgress>> achievements = ref.watch(
      achievementsProvider,
    );
    return achievements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: _RetryCard(onRetry: () => ref.invalidate(achievementsProvider)),
      ),
      data: (List<AchievementProgress> values) {
        final LocaleFormatting formatting = _formatting(context);
        return ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.space16),
          itemCount: values.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: DesignTokens.space8),
          itemBuilder: (BuildContext context, int index) {
            final AchievementProgress achievement = values[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  achievement.isUnlocked
                      ? Icons.emoji_events
                      : Icons.lock_outline,
                  color: achievement.isUnlocked
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(_achievementTitle(strings, achievement.id)),
                subtitle: Text(
                  achievement.isUnlocked
                      ? strings.unlockedOn(
                          formatting.formatDate(
                            achievement.unlockedAt!.toLocal(),
                          ),
                        )
                      : strings.achievementProgress(
                          achievement.progress,
                          achievement.target,
                        ),
                ),
                trailing: Text(
                  achievement.isUnlocked
                      ? strings.achievementUnlocked
                      : strings.achievementLocked,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

final class _StatisticTile extends StatelessWidget {
  const _StatisticTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

final class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label)),
          const SizedBox(width: DesignTokens.space16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: Column(
          children: <Widget>[
            const Icon(Icons.history_toggle_off, size: 48),
            const SizedBox(height: DesignTokens.space12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space24),
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(strings.retry),
        ),
      ),
    );
  }
}

LocaleFormatting _formatting(BuildContext context) {
  final Locale locale = Localizations.localeOf(context);
  return LocaleFormatting(
    SupportedLanguages.resolveSystem(
      languageCode: locale.languageCode,
      scriptCode: locale.scriptCode,
    ),
  );
}

String _modeLabel(AppLocalizations strings, GameMode mode) {
  return switch (mode) {
    GameMode.computer => strings.computer,
    GameMode.local => strings.localTwoPlayer,
    GameMode.friend => strings.friendPlayer,
  };
}

String _outcomeLabel(AppLocalizations strings, MatchOutcome outcome) {
  return switch (outcome) {
    MatchOutcome.win => strings.winResult,
    MatchOutcome.loss => strings.lossResult,
    MatchOutcome.draw => strings.drawResult,
  };
}

String _difficultyLabel(
  AppLocalizations strings,
  ComputerDifficulty difficulty,
) {
  return switch (difficulty) {
    ComputerDifficulty.beginner => strings.beginner,
    ComputerDifficulty.intermediate => strings.intermediate,
    ComputerDifficulty.expert => strings.expert,
    ComputerDifficulty.grandmaster => strings.grandmaster,
  };
}

String _achievementTitle(AppLocalizations strings, AchievementId id) {
  return switch (id) {
    AchievementId.firstMove => strings.achievementFirstMove,
    AchievementId.firstWin => strings.achievementFirstWin,
    AchievementId.firstCheckmate => strings.achievementFirstCheckmate,
    AchievementId.winAsBlack => strings.achievementWinAsBlack,
    AchievementId.castleSuccessfully => strings.achievementCastleSuccessfully,
    AchievementId.promotePawn => strings.achievementPromotePawn,
    AchievementId.puzzleBeginner => strings.achievementPuzzleBeginner,
    AchievementId.puzzleSolver => strings.achievementPuzzleSolver,
    AchievementId.challengeStarter => strings.achievementChallengeStarter,
    AchievementId.challengeMaster => strings.achievementChallengeMaster,
    AchievementId.noHintVictory => strings.achievementNoHintVictory,
    AchievementId.tenGamesPlayed => strings.achievementTenGamesPlayed,
    AchievementId.fiftyGamesPlayed => strings.achievementFiftyGamesPlayed,
    AchievementId.localMatchCompleted => strings.achievementLocalMatchCompleted,
    AchievementId.friendMatchCompleted =>
      strings.achievementFriendMatchCompleted,
  };
}
