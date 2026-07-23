import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/model/game_result.dart';
import '../../domain/model/piece_color.dart';

enum MatchResultAction { rematch, review, exportPgn, home }

final class MatchResultDialog extends StatelessWidget {
  const MatchResultDialog({
    required this.result,
    required this.duration,
    required this.moveCount,
    required this.captureCount,
    required this.hintCount,
    super.key,
  });

  final GameResult result;
  final Duration duration;
  final int moveCount;
  final int captureCount;
  final int hintCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String title = result.isDraw
        ? strings.gameDrawn
        : strings.gameWonBy(
            result.winner == PieceColor.white ? strings.white : strings.black,
          );
    final String reason = _reason(strings);
    return AlertDialog(
      icon: Icon(
        result.isDraw ? Icons.handshake_outlined : Icons.emoji_events_outlined,
        size: 44,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                reason,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignTokens.space20),
              _SummaryRow(label: strings.result, value: result.notation),
              _SummaryRow(
                label: strings.duration,
                value: _formatDuration(duration),
              ),
              _SummaryRow(label: strings.moves, value: '$moveCount'),
              _SummaryRow(label: strings.captures, value: '$captureCount'),
              _SummaryRow(label: strings.hintsUsed, value: '$hintCount'),
              _SummaryRow(
                label: strings.coinReward,
                value: strings.noRewardThisMode,
              ),
              _SummaryRow(
                label: strings.challengeProgress,
                value: strings.notApplicable,
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(MatchResultAction.review),
          icon: const Icon(Icons.rate_review_outlined),
          label: Text(strings.reviewGame),
        ),
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(MatchResultAction.exportPgn),
          icon: const Icon(Icons.copy_outlined),
          label: Text(strings.copyPgn),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(MatchResultAction.home),
          icon: const Icon(Icons.home_outlined),
          label: Text(strings.returnHome),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(MatchResultAction.rematch),
          icon: const Icon(Icons.replay),
          label: Text(strings.rematch),
        ),
      ],
    );
  }

  String _reason(AppLocalizations strings) {
    return switch (result.reason) {
      GameResultReason.checkmate => strings.resultCheckmate,
      GameResultReason.stalemate => strings.resultStalemate,
      GameResultReason.threefoldRepetition => strings.resultThreefoldRepetition,
      GameResultReason.fiftyMoveRule => strings.resultFiftyMoveRule,
      GameResultReason.insufficientMaterial =>
        strings.resultInsufficientMaterial,
      GameResultReason.drawAgreement => strings.resultDrawAgreement,
      GameResultReason.resignation => strings.resultResignation,
      GameResultReason.timeout => strings.resultTimeout,
      GameResultReason.adjudication => strings.resultAdjudication,
    };
  }

  String _formatDuration(Duration value) {
    final int minutes = value.inMinutes;
    final int seconds = value.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          const SizedBox(width: DesignTokens.space16),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
