import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/creator_watermark.dart';
import '../../../l10n/app_localizations.dart';
import '../application/challenge_providers.dart';
import '../application/daily_challenges_controller.dart';
import '../domain/challenge_dashboard.dart';
import '../domain/daily_challenge.dart';
import '../domain/local_date.dart';
import '../domain/reward_wallet.dart';
import 'widgets/reward_balance_bar.dart';

final class DailyChallengesScreen extends ConsumerStatefulWidget {
  const DailyChallengesScreen({super.key});

  @override
  ConsumerState<DailyChallengesScreen> createState() =>
      _DailyChallengesScreenState();
}

final class _DailyChallengesScreenState
    extends ConsumerState<DailyChallengesScreen> {
  Timer? _countdownTimer;
  Timer? _celebrationTimer;
  String? _celebratingChallengeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(dailyChallengesControllerProvider).initialize());
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      unawaited(
        ref.read(dailyChallengesControllerProvider).refreshIfDateChanged(),
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _celebrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final DailyChallengesController controller = ref.watch(
      dailyChallengesControllerProvider,
    );
    final ChallengeDashboard? dashboard = controller.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.dailyChallengesTitle),
        actions: <Widget>[
          if (kDebugMode)
            IconButton(
              tooltip: strings.developerChallengeDate,
              onPressed: () => _showDeveloperDateTools(controller),
              icon: const Icon(Icons.developer_mode_outlined),
            ),
          IconButton(
            tooltip: strings.refresh,
            onPressed: controller.isLoading ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
            children: <Widget>[
              Text(
                strings.dailyChallengesSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: DesignTokens.space8),
              Text(
                strings.challengeRefreshCountdown(
                  _formatDuration(controller.untilRefresh),
                ),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (controller.simulatedDate != null) ...<Widget>[
                const SizedBox(height: DesignTokens.space8),
                Chip(
                  avatar: const Icon(Icons.science_outlined),
                  label: Text(
                    strings.challengeSimulatedDate(
                      controller.simulatedDate!.value,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.space16),
              if (dashboard != null)
                RewardBalanceBar(
                  wallet: dashboard.wallet,
                  onHintShop: _showHintShop,
                  onLedger: () => _showLedger(controller),
                ),
              if (dashboard != null) ...<Widget>[
                const SizedBox(height: DesignTokens.space8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Chip(
                    avatar: const Icon(Icons.local_fire_department_outlined),
                    label: Text(strings.dailyStreak(dashboard.currentStreak)),
                  ),
                ),
              ],
              if (controller.isLoading && dashboard == null)
                const Padding(
                  padding: EdgeInsets.all(DesignTokens.space32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dashboard != null) ...<Widget>[
                const SizedBox(height: DesignTokens.space8),
                for (final DailyChallenge challenge in dashboard.today) ...[
                  _ChallengeCard(
                    challenge: challenge,
                    celebrating: _celebratingChallengeId == challenge.id,
                    claiming: controller.claimingChallengeId == challenge.id,
                    onClaim: challenge.isCompleted && !challenge.isClaimed
                        ? () => _claim(controller, challenge)
                        : null,
                  ),
                  const SizedBox(height: DesignTokens.space12),
                ],
                const SizedBox(height: DesignTokens.space8),
                _OfflineNotice(text: strings.challengeOfflineNotice),
                const SizedBox(height: DesignTokens.space24),
                Text(
                  strings.challengeHistory,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: DesignTokens.space8),
                if (dashboard.history.isEmpty)
                  Text(strings.challengeHistoryEmpty)
                else
                  _ChallengeHistory(challenges: dashboard.history),
              ],
              if (controller.errorCode != null) ...<Widget>[
                const SizedBox(height: DesignTokens.space16),
                _ErrorPanel(
                  message: _errorMessage(strings, controller.errorCode!),
                  onRetry: controller.refresh,
                ),
              ],
              const SizedBox(height: DesignTokens.space32),
              const CreatorWatermark(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claim(
    DailyChallengesController controller,
    DailyChallenge challenge,
  ) async {
    final bool newlyClaimed = await controller.claim(challenge.id);
    if (!mounted || !newlyClaimed) {
      return;
    }
    setState(() => _celebratingChallengeId = challenge.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).challengeRewardClaimedMessage,
          ),
        ),
      );
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && _celebratingChallengeId == challenge.id) {
        setState(() => _celebratingChallengeId = null);
      }
    });
  }

  Future<void> _showDeveloperDateTools(
    DailyChallengesController controller,
  ) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  strings.developerChallengeDate,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(strings.developerDateExplanation),
                const SizedBox(height: DesignTokens.space16),
                OutlinedButton(
                  onPressed: () async {
                    final DateTime initial =
                        controller.simulatedDate?.start ?? DateTime.now();
                    final DateTime? selected = await showDatePicker(
                      context: sheetContext,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                      initialDate: initial,
                    );
                    if (selected != null) {
                      await controller.simulateDate(
                        LocalDate.fromLocal(selected),
                      );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    }
                  },
                  child: Text(strings.developerChallengeDate),
                ),
                TextButton(
                  onPressed: () async {
                    await controller.simulateDate(null);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Text(strings.developerUseActualDate),
                ),
                TextButton(
                  onPressed: () async {
                    await controller.resetCurrentDate();
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Text(strings.developerResetChallenges),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHintShop() {
    final AppLocalizations strings = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.lightbulb_outline),
          title: Text(strings.hintShop),
          content: Text(strings.hintShopDescription),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLedger(DailyChallengesController controller) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final (List<RewardLedgerEntry>, LedgerIntegrityReport) values = await (
      controller.readLedger(),
      controller.verifyLedgerIntegrity(),
    ).wait;
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          builder: (BuildContext context, ScrollController scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(DesignTokens.space20),
              children: <Widget>[
                Text(
                  strings.rewardLedger,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: DesignTokens.space8),
                Text(
                  values.$2.isValid
                      ? strings.rewardLedgerIntegrityValid(
                          values.$2.checkedEntries,
                        )
                      : strings.rewardLedgerIntegrityInvalid,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => _copyLedger(values.$1),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(strings.copyRewardLedger),
                  ),
                ),
                const Divider(height: 32),
                if (values.$1.isEmpty)
                  Text(strings.rewardLedgerEmpty)
                else
                  for (final RewardLedgerEntry entry in values.$1)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.asset == RewardAsset.coin
                            ? Icons.monetization_on_outlined
                            : Icons.lightbulb_outline,
                      ),
                      title: Text(
                        '${entry.amount > 0 ? '+' : ''}${entry.amount} '
                        '${entry.asset.name}',
                      ),
                      subtitle: Text(
                        '${entry.type.name} · ${entry.source}\n'
                        '${entry.balanceBefore} → ${entry.balanceAfter}',
                      ),
                      isThreeLine: true,
                      trailing: Text('#${entry.sequence}'),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _copyLedger(List<RewardLedgerEntry> entries) async {
    final String encoded = const JsonEncoder.withIndent('  ').convert(
      entries
          .map((RewardLedgerEntry entry) {
            return <String, Object?>{
              'transactionId': entry.id,
              'sequence': entry.sequence,
              'transactionType': entry.type.name,
              'assetType': entry.asset.name,
              'amount': entry.amount,
              'balanceBefore': entry.balanceBefore,
              'balanceAfter': entry.balanceAfter,
              'source': entry.source,
              'timestamp': entry.timestamp.toUtc().toIso8601String(),
              'relatedChallengeId': entry.relatedChallengeId,
              'appVersion': entry.appVersion,
              'previousIntegrityHash': entry.previousIntegrityHash,
              'integrityHash': entry.integrityHash,
            };
          })
          .toList(growable: false),
    );
    await Clipboard.setData(ClipboardData(text: encoded));
    if (mounted) {
      _showSnackBar(AppLocalizations.of(context).rewardLedgerCopied);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(AppLocalizations strings, String code) {
    return switch (code) {
      'challenge_load_failed' => strings.challengeLoadFailed,
      'challenge_progress_failed' => strings.challengeProgressFailed,
      'challenge_incomplete' => strings.challengeIncompleteError,
      'challenge_not_found' => strings.challengeNotFoundError,
      _ => strings.challengeClaimFailed,
    };
  }
}

final class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.celebrating,
    required this.claiming,
    required this.onClaim,
  });

  final DailyChallenge challenge;
  final bool celebrating;
  final bool claiming;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedScale(
                  scale: celebrating ? 1.35 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    challenge.isCompleted
                        ? Icons.emoji_events_outlined
                        : Icons.flag_outlined,
                    color: challenge.isCompleted
                        ? colors.tertiary
                        : colors.primary,
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _title(strings, challenge.type),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      Text(_description(strings, challenge.type)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space12),
            Semantics(
              label: '${challenge.currentProgress} of ${challenge.targetValue}',
              value: '${(challenge.progress * 100).round()}%',
              child: LinearProgressIndicator(value: challenge.progress),
            ),
            const SizedBox(height: DesignTokens.space8),
            Row(
              children: <Widget>[
                Text(
                  '${challenge.currentProgress}/${challenge.targetValue}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                Text(
                  _rewardLabel(strings, challenge.reward),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (challenge.isCompleted) ...<Widget>[
              const SizedBox(height: DesignTokens.space12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: challenge.isClaimed
                    ? Chip(
                        avatar: const Icon(Icons.check, size: 18),
                        label: Text(strings.challengeClaimed),
                      )
                    : FilledButton.icon(
                        onPressed: claiming ? null : onClaim,
                        icon: claiming
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.redeem_outlined),
                        label: Text(strings.challengeClaim),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.offline_bolt_outlined),
            const SizedBox(width: DesignTokens.space12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

final class _ChallengeHistory extends StatelessWidget {
  const _ChallengeHistory({required this.challenges});

  final List<DailyChallenge> challenges;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: <Widget>[
          for (final DailyChallenge challenge in challenges.take(30))
            ListTile(
              leading: Icon(
                challenge.isClaimed
                    ? Icons.check_circle_outline
                    : challenge.isCompleted
                    ? Icons.task_alt
                    : Icons.timelapse,
              ),
              title: Text(_title(strings, challenge.type)),
              subtitle: Text(challenge.date.value),
              trailing: Text(
                challenge.isClaimed
                    ? strings.challengeClaimed
                    : '${challenge.currentProgress}/${challenge.targetValue}',
              ),
            ),
        ],
      ),
    );
  }
}

final class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).retry),
        ),
      ),
    );
  }
}

String _title(AppLocalizations strings, ChallengeType type) {
  return switch (type) {
    ChallengeType.playLegalMoves => strings.challengePlayMovesTitle,
    ChallengeType.finishMatch => strings.challengeFinishMatchTitle,
    ChallengeType.noHintMatch => strings.challengeNoHintTitle,
    ChallengeType.winAsWhite => strings.challengeWinWhiteTitle,
    ChallengeType.winAsBlack => strings.challengeWinBlackTitle,
    ChallengeType.beginnerWin => strings.challengeBeginnerWinTitle,
    ChallengeType.intermediateWin => strings.challengeIntermediateWinTitle,
    ChallengeType.captureQueen => strings.challengeCaptureQueenTitle,
    ChallengeType.castle => strings.challengeCastleTitle,
    ChallengeType.promotePawn => strings.challengePromotionTitle,
    ChallengeType.enPassantCapture => strings.challengeEnPassantTitle,
    ChallengeType.localMatch => strings.challengeLocalMatchTitle,
  };
}

String _description(AppLocalizations strings, ChallengeType type) {
  return switch (type) {
    ChallengeType.playLegalMoves => strings.challengePlayMovesDescription,
    ChallengeType.finishMatch => strings.challengeFinishMatchDescription,
    ChallengeType.noHintMatch => strings.challengeNoHintDescription,
    ChallengeType.winAsWhite => strings.challengeWinWhiteDescription,
    ChallengeType.winAsBlack => strings.challengeWinBlackDescription,
    ChallengeType.beginnerWin => strings.challengeBeginnerWinDescription,
    ChallengeType.intermediateWin =>
      strings.challengeIntermediateWinDescription,
    ChallengeType.captureQueen => strings.challengeCaptureQueenDescription,
    ChallengeType.castle => strings.challengeCastleDescription,
    ChallengeType.promotePawn => strings.challengePromotionDescription,
    ChallengeType.enPassantCapture => strings.challengeEnPassantDescription,
    ChallengeType.localMatch => strings.challengeLocalMatchDescription,
  };
}

String _rewardLabel(AppLocalizations strings, ChallengeReward reward) {
  if (reward.coins > 0 && reward.hints > 0) {
    return strings.challengeRewardBoth(reward.coins, reward.hints);
  }
  if (reward.coins > 0) {
    return strings.challengeRewardCoins(reward.coins);
  }
  return strings.challengeRewardHints(reward.hints);
}
