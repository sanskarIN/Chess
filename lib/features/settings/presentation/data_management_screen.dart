import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/data_management_providers.dart';
import '../data/local_data_service.dart';
import '../domain/data_snapshot.dart';

final class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations s = AppLocalizations.of(context);
    final LocalDataService service = ref.watch(localDataServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.dataManagement)),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: Text(s.viewLocalData),
            subtitle: Text(s.dataRetentionExplanation),
            onTap: () => _showDiagnostics(context, service),
          ),
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: Text(s.exportData),
            subtitle: Text(s.copyDataSnapshot),
            onTap: () => _export(context, service),
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_outlined),
            title: Text(s.importData),
            subtitle: Text(s.previewImport),
            onTap: () => _import(context, service),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_toggle_off_outlined),
            title: Text(s.deleteMatchHistory),
            onTap: () => _confirm(context, service.deleteMatchHistory),
          ),
          ListTile(
            leading: const Icon(Icons.query_stats_outlined),
            title: Text(s.resetStatistics),
            onTap: () => _confirm(context, service.resetStatistics),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_remove_outlined),
            title: Text(s.deleteSavedGames),
            onTap: () => _confirm(context, () => service.deleteSavedGames()),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: Text(s.resetChallenges),
            onTap: () => _confirm(context, service.resetChallenges),
          ),
          ListTile(
            leading: const Icon(Icons.money_off_outlined),
            title: Text(s.resetCoinsHints),
            onTap: () => _confirm(context, service.resetRewards),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(s.clearRecentOpponents),
            onTap: () => _confirm(context, service.clearRecentOpponents),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(s.exportRewardLedger),
            onTap: () => _exportLedger(context, service),
          ),
          ListTile(
            textColor: Theme.of(context).colorScheme.error,
            iconColor: Theme.of(context).colorScheme.error,
            leading: const Icon(Icons.delete_forever),
            title: Text(s.deleteAllLocalData),
            subtitle: Text(s.strongConfirmation),
            onTap: () =>
                _confirm(context, service.deleteAllLocalData, strong: true),
          ),
        ],
      ),
    );
  }

  Future<void> _showDiagnostics(
    BuildContext context,
    LocalDataService service,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      final StorageDiagnostic diagnostic = await service.diagnostics();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.viewLocalData),
          content: SingleChildScrollView(
            child: Text(
              '${s.databaseIntegrityResult(diagnostic.integrityResult)}\n'
              '${s.diagnosticDatabase}: ${diagnostic.schemaVersion}\n'
              '${s.diagnosticMigration}: ${diagnostic.lastMigrationStatus}\n\n'
              '${diagnostic.tableCounts.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.close),
            ),
          ],
        ),
      );
    } on Object {
      if (context.mounted) _message(context, s.dataActionFailed);
    }
  }

  Future<void> _export(BuildContext context, LocalDataService service) async {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      final String snapshot = await service.exportSnapshot();
      await Clipboard.setData(ClipboardData(text: snapshot));
      if (context.mounted) _message(context, s.dataActionCompleted);
    } on Object {
      if (context.mounted) _message(context, s.dataActionFailed);
    }
  }

  Future<void> _exportLedger(
    BuildContext context,
    LocalDataService service,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      final String snapshot = await service.exportRewardLedger();
      await Clipboard.setData(ClipboardData(text: snapshot));
      if (context.mounted) _message(context, s.rewardLedgerCopied);
    } on Object {
      if (context.mounted) _message(context, s.dataActionFailed);
    }
  }

  Future<void> _import(BuildContext context, LocalDataService service) async {
    final AppLocalizations s = AppLocalizations.of(context);
    String source = '';
    DataSnapshotPreview? preview;
    final DataImportMode? mode = await showDialog<DataImportMode>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.importData),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  minLines: 5,
                  maxLines: 12,
                  decoration: InputDecoration(labelText: s.pasteDataSnapshot),
                  onChanged: (value) => source = value,
                ),
                if (preview != null)
                  Text(
                    s.snapshotPreview(
                      preview!.tableCounts.length,
                      preview!.totalRows,
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    try {
                      setState(() => preview = service.preview(source));
                    } on Object {
                      setState(() => preview = null);
                    }
                  },
                  child: Text(s.previewImport),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: preview == null
                  ? null
                  : () => Navigator.pop(dialogContext, DataImportMode.merge),
              child: Text(s.mergeImport),
            ),
            FilledButton(
              onPressed: preview == null
                  ? null
                  : () => Navigator.pop(dialogContext, DataImportMode.replace),
              child: Text(s.replaceImport),
            ),
          ],
        ),
      ),
    );
    if (mode != null) {
      try {
        await service.importSnapshot(source, mode: mode);
        if (context.mounted) _message(context, s.dataActionCompleted);
      } on Object {
        if (context.mounted) _message(context, s.dataActionFailed);
      }
    }
  }

  Future<void> _confirm(
    BuildContext context,
    Future<void> Function() action, {
    bool strong = false,
  }) async {
    final AppLocalizations s = AppLocalizations.of(context);
    String confirmation = '';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.strongConfirmation),
        content: strong
            ? TextField(
                decoration: InputDecoration(
                  labelText: s.deleteConfirmationWord,
                ),
                onChanged: (value) => confirmation = value,
              )
            : Text(s.deleteSavedGameDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!strong || confirmation == s.deleteConfirmationWord) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await action();
      if (context.mounted) _message(context, s.dataActionCompleted);
    } on Object {
      if (context.mounted) _message(context, s.dataActionFailed);
    }
  }

  void _message(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
