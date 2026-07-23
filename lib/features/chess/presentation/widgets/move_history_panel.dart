import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/model/move_record.dart';

final class MoveHistoryPanel extends StatelessWidget {
  const MoveHistoryPanel({required this.records, super.key});

  final List<MoveRecord> records;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.format_list_numbered),
                const SizedBox(width: DesignTokens.space8),
                Text(
                  strings.moveHistory,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(strings.moveCount(records.length)),
              ],
            ),
            const SizedBox(height: DesignTokens.space12),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.space20,
                ),
                child: Text(
                  strings.noMovesYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Semantics(
                label: strings.moveHistory,
                child: Table(
                  columnWidths: const <int, TableColumnWidth>{
                    0: FixedColumnWidth(42),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                  },
                  children: _rows(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _rows(BuildContext context) {
    final List<TableRow> rows = <TableRow>[];
    for (int index = 0; index < records.length; index += 2) {
      final MoveRecord white = records[index];
      final MoveRecord? black = index + 1 < records.length
          ? records[index + 1]
          : null;
      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: (index ~/ 2).isEven
                ? Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          children: <Widget>[
            _HistoryCell('${(index ~/ 2) + 1}.', muted: true),
            _HistoryCell(white.san),
            _HistoryCell(black?.san ?? '—'),
          ],
        ),
      );
    }
    return rows;
  }
}

final class _HistoryCell extends StatelessWidget {
  const _HistoryCell(this.value, {this.muted = false});

  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        value,
        style: muted
            ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
            : const TextStyle(fontFeatures: <FontFeature>[]),
      ),
    );
  }
}
