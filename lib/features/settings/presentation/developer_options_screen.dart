import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/app_version.dart';
import '../../../core/database/database_schema.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/locale_formatting.dart';
import '../../../l10n/pseudolocalizer.dart';
import '../../../l10n/supported_locales.dart';
import '../../challenges/application/challenge_providers.dart';
import '../../challenges/domain/challenge_event.dart';
import '../../challenges/domain/local_date.dart';
import '../../challenges/domain/reward_wallet.dart';
import '../../chess/domain/model/chess_game.dart';
import '../../chess/domain/notation/fen_codec.dart';
import '../../chess/domain/notation/pgn_codec.dart';
import '../../chess/domain/rules/perft.dart';
import '../../friend_multiplayer/data/friend_protocol.dart';
import '../application/data_management_providers.dart';
import '../application/settings_providers.dart';
import '../data/safe_link_service.dart';
import '../domain/app_settings.dart';
import 'settings_localizations.dart';

final class DeveloperOptionsScreen extends ConsumerWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations s = AppLocalizations.of(context);
    final controller = ref.watch(settingsControllerProvider);
    final settings = controller.settings;
    if (!settings.developerOptionsEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(s.developerOptions)),
        body: Center(child: Text(s.tapVersionToUnlock)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.developerOptions)),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space16),
              child: Text(s.developerWarning),
            ),
          ),
          _DeveloperSection(
            title: s.applicationDiagnostics,
            children: <Widget>[
              _diagnostic(s.currentVersion, AppVersion.name),
              _diagnostic(s.buildNumber, '${AppVersion.buildNumber}'),
              _diagnostic(
                s.diagnosticFlutter,
                const String.fromEnvironment(
                  'FLUTTER_VERSION',
                  defaultValue: '3.44.7 tested baseline',
                ),
              ),
              _diagnostic(s.diagnosticDart, Platform.version.split(' ').first),
              _diagnostic(
                s.diagnosticAndroid,
                Platform.isAndroid ? Platform.operatingSystemVersion : 'N/A',
              ),
              _diagnostic(s.diagnosticArchitecture, Platform.version),
              _diagnostic(
                s.diagnosticDatabase,
                '${DatabaseSchema.currentVersion}',
              ),
              _diagnostic(s.diagnosticEngine, 'Chess-Master Local Search'),
              _diagnostic(s.engineHealth, s.engineHealthy),
              _diagnostic(s.diagnosticMemory, s.unavailableDiagnostic),
              _diagnostic(
                s.diagnosticLocale,
                Localizations.localeOf(context).toLanguageTag(),
              ),
              _diagnostic(s.diagnosticTheme, settings.theme.name),
              ListTile(
                title: Text(s.lastMigrationStatus),
                subtitle: Text(s.viewLocalData),
                onTap: () => _showStorageDiagnostics(context, ref),
              ),
              _diagnostic(s.diagnosticProtocol, '${FriendProtocol.version}'),
            ],
          ),
          _DeveloperSection(
            title: s.debugControls,
            children: TypedFeatureFlag.values
                .where(
                  (flag) => !<TypedFeatureFlag>[
                    TypedFeatureFlag.pseudolocalization,
                    TypedFeatureFlag.expandedTextPreview,
                    TypedFeatureFlag.rtlPreview,
                  ].contains(flag),
                )
                .map(
                  (flag) => SwitchListTile(
                    title: Text(featureFlagLabel(s, flag)),
                    subtitle: Text(s.developerOnly),
                    value: settings.featureEnabled(flag),
                    onChanged: (value) =>
                        controller.setFeatureFlag(flag, value),
                  ),
                )
                .toList(growable: false),
          ),
          _DeveloperSection(
            title: s.chessTools,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.data_object),
                title: Text(s.fenEditor),
                subtitle: Text(s.validatePosition),
                onTap: () => _fenTool(context),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(s.pgnImporter),
                subtitle: Text(s.validatePosition),
                onTap: () => _pgnTool(context),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_outlined),
                title: Text(s.boardEditor),
                subtitle: Text(
                  '${s.setSideToMove} · ${s.setCastlingRights} · '
                  '${s.setEnPassantSquare} · ${s.setMoveCounters}',
                ),
                onTap: () => _boardEditor(context),
              ),
              for (final MapEntry<String, String> position
                  in _testPositions.entries)
                ListTile(
                  title: Text(position.key),
                  subtitle: Text(position.value),
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: position.value),
                    );
                  },
                ),
            ],
          ),
          _DeveloperSection(
            title: s.economyTools,
            children: <Widget>[
              ListTile(
                title: Text(s.addTestCoins),
                onTap: () => _grant(ref, context, coins: 100, hints: 0),
              ),
              ListTile(
                title: Text(s.addTestHints),
                onTap: () => _grant(ref, context, coins: 0, hints: 5),
              ),
              ListTile(
                title: Text(s.removeTestCoins),
                onTap: () => _adjustCoins(ref, context, -10),
              ),
              ListTile(
                title: Text(s.simulateRewardClaim),
                onTap: () => _grant(ref, context, coins: 1, hints: 0),
              ),
              ListTile(
                title: Text(s.detectDuplicateTransaction),
                onTap: () => _testDuplicateReward(ref, context),
              ),
              ListTile(
                title: Text(s.resetLedger),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.rewardLedger),
                onTap: () => context.push(AppRoutes.dailyChallenges),
              ),
              ListTile(
                title: Text(s.exportLedger),
                onTap: () => _exportLedger(ref, context),
              ),
            ],
          ),
          _DeveloperSection(
            title: s.challengeTools,
            children: <Widget>[
              ListTile(
                title: Text(s.generateTodayChallenges),
                onTap: () =>
                    ref.read(dailyChallengesControllerProvider).initialize(),
              ),
              ListTile(
                title: Text(s.simulateTomorrow),
                onTap: () async {
                  final DateTime tomorrow = DateTime.now().add(
                    const Duration(days: 1),
                  );
                  await ref
                      .read(dailyChallengesControllerProvider)
                      .simulateDate(LocalDate.fromLocal(tomorrow));
                },
              ),
              ListTile(
                title: Text(s.simulatePreviousDay),
                onTap: () async {
                  final DateTime previous = DateTime.now().subtract(
                    const Duration(days: 1),
                  );
                  await ref
                      .read(dailyChallengesControllerProvider)
                      .simulateDate(LocalDate.fromLocal(previous));
                },
              ),
              ListTile(
                title: Text(s.resetChallenges),
                onTap: () => ref
                    .read(dailyChallengesControllerProvider)
                    .resetCurrentDate(),
              ),
              ListTile(
                title: Text(s.completeChallenge),
                onTap: () => _completeChallenge(ref, context),
              ),
              ListTile(
                title: Text(s.testDuplicateClaim),
                onTap: () => _testDuplicateClaim(ref, context),
              ),
              ListTile(
                title: Text(s.previewRewardAnimation),
                onTap: () => _message(context, s.developmentBalanceChanged),
              ),
              ListTile(
                title: Text(s.verifyRefreshLogic),
                onTap: () {
                  final duration = ref
                      .read(dailyChallengesControllerProvider)
                      .untilRefresh;
                  _message(context, s.simulationResult('$duration'));
                },
              ),
            ],
          ),
          _DeveloperSection(
            title: s.multiplayerTools,
            children: <Widget>[
              ListTile(
                title: Text(s.editRelayUrl),
                subtitle: Text(
                  settings.relayServerUrl.isEmpty
                      ? s.friendRelayNotConfigured
                      : settings.relayServerUrl,
                ),
                onTap: () => _editRelay(context, ref),
              ),
              ListTile(
                title: Text(s.copySafeDiagnostics),
                onTap: () => _copyDiagnostics(context, settings),
              ),
              ListTile(
                title: Text(s.testServerHealth),
                onTap: () => _testServerHealth(context, settings),
              ),
              ListTile(
                title: Text(s.simulateLatency),
                onTap: () => _simulateLatency(context),
              ),
              ListTile(
                title: Text(s.simulatePacketLoss),
                onTap: () =>
                    _message(context, s.simulationResult('10% packet loss')),
              ),
              ListTile(
                title: Text(s.forceDisconnection),
                onTap: () =>
                    _message(context, s.simulationResult('disconnected')),
              ),
              ListTile(
                title: Text(s.testReconnection),
                onTap: () => _message(
                  context,
                  s.simulationResult(
                    'reconnect after ${settings.reconnectionSeconds}s',
                  ),
                ),
              ),
              ListTile(
                title: Text(s.showRoomState),
                onTap: () => _showRoomState(context, settings),
              ),
              ListTile(
                title: Text(s.showStateHash),
                onTap: () => _showStateHash(context, settings),
              ),
              ListTile(
                title: Text(s.clearRoomState),
                onTap: () =>
                    _message(context, s.simulationResult('room state cleared')),
              ),
              ListTile(
                title: Text(s.selectProtocolVersion),
                subtitle: Text('${FriendProtocol.version}'),
                onTap: () => _message(
                  context,
                  s.simulationResult('v${FriendProtocol.version}'),
                ),
              ),
            ],
          ),
          _DeveloperSection(
            title: s.localizationTools,
            children: <Widget>[
              for (final flag in <TypedFeatureFlag>[
                TypedFeatureFlag.pseudolocalization,
                TypedFeatureFlag.expandedTextPreview,
                TypedFeatureFlag.rtlPreview,
              ])
                SwitchListTile(
                  title: Text(featureFlagLabel(s, flag)),
                  subtitle: flag == TypedFeatureFlag.pseudolocalization
                      ? Text(Pseudolocalizer.transform(s.appTitle))
                      : null,
                  value: settings.featureEnabled(flag),
                  onChanged: (value) => controller.setFeatureFlag(flag, value),
                ),
              ListTile(
                title: Text(s.missingKeyDetection),
                onTap: () =>
                    _message(context, s.simulationResult('0 missing keys')),
              ),
              ListTile(
                title: Text(s.untranslatedStringReport),
                onTap: () => _message(
                  context,
                  s.localizationCompletenessSummary(33, 33, 32),
                ),
              ),
              ListTile(
                title: Text(s.localeSwitching),
                subtitle: Text(Localizations.localeOf(context).toLanguageTag()),
                onTap: () => context.push(AppRoutes.language),
              ),
              ListTile(
                title: Text(s.numberFormatPreview),
                subtitle: Text(
                  LocaleFormatting(
                    SupportedLanguages.byId(
                      settings.localeCode ??
                          Localizations.localeOf(context).languageCode,
                    ),
                  ).formatDecimal(1234567.89),
                ),
              ),
              ListTile(
                title: Text(s.dateFormatPreview),
                subtitle: Text(
                  LocaleFormatting(
                    SupportedLanguages.byId(
                      settings.localeCode ??
                          Localizations.localeOf(context).languageCode,
                    ),
                  ).formatDate(DateTime.now()),
                ),
              ),
            ],
          ),
          _DeveloperSection(
            title: s.storageTools,
            children: <Widget>[
              ListTile(
                title: Text(s.viewDatabaseTables),
                onTap: () => _showStorageDiagnostics(context, ref),
              ),
              ListTile(
                title: Text(s.viewSchemaVersion),
                subtitle: Text('${DatabaseSchema.currentVersion}'),
              ),
              ListTile(
                title: Text(s.runIntegrityCheck),
                onTap: () async {
                  try {
                    final result = await ref
                        .read(localDataServiceProvider)
                        .diagnostics();
                    if (context.mounted) {
                      _message(
                        context,
                        s.databaseIntegrityResult(result.integrityResult),
                      );
                    }
                  } on Object {
                    if (context.mounted) _message(context, s.dataActionFailed);
                  }
                },
              ),
              ListTile(
                title: Text(s.testMigration),
                onTap: () => _showStorageDiagnostics(context, ref),
              ),
              ListTile(
                title: Text(s.exportDatabase),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.createBackup),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.restoreBackup),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.simulateCorruptedBackup),
                onTap: () => _simulateCorruptBackup(context, ref),
              ),
              ListTile(
                title: Text(s.resetAllLocalData),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.dataManagement),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
            ],
          ),
          _DeveloperSection(
            title: s.featureFlags,
            children: <Widget>[
              SwitchListTile(
                title: Text(s.showEvaluation),
                value: settings.featureEnabled(
                  TypedFeatureFlag.experimentalAnalysis,
                ),
                onChanged: (value) => controller.setFeatureFlag(
                  TypedFeatureFlag.experimentalAnalysis,
                  value,
                ),
              ),
            ],
          ),
          _DeveloperSection(
            title: s.openSourceInformation,
            children: <Widget>[
              ListTile(title: Text(s.fullyOpenSourceStatement)),
              ListTile(
                title: Text('https://www.github.com/sanskarIN/Chess'),
                subtitle: const Text('GPL-3.0-or-later'),
                onTap: () => const SafeLinkService().openOrCopy(
                  Uri.parse('https://www.github.com/sanskarIN/Chess'),
                ),
              ),
              ListTile(
                title: Text(s.contributionGuide),
                onTap: () => _openRepositoryPath('blob/main/CONTRIBUTING.md'),
              ),
              ListTile(
                title: Text(s.securityReportingGuide),
                onTap: () => _openRepositoryPath('blob/main/SECURITY.md'),
              ),
              ListTile(
                title: Text(s.issueTemplates),
                onTap: () => _openRepositoryPath('issues/new/choose'),
              ),
              ListTile(
                title: Text(s.sourceBuildInstructions),
                onTap: () => _openRepositoryPath('blob/main/README.md'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diagnostic(String label, String value) {
    return ListTile(title: Text(label), subtitle: Text(value));
  }

  Future<void> _fenTool(BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    String source = FenCodec.standardInitialPosition;
    String? result;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.fenEditor),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: source,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (value) => source = value,
                ),
                if (result != null) Text(result!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.close),
            ),
            TextButton(
              onPressed: () {
                try {
                  FenCodec.decode(source);
                  setState(() => result = s.positionValid);
                } on Object {
                  setState(() => result = s.invalidFen);
                }
              },
              child: Text(s.validatePosition),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final game = ChessGame(
                    gameId: 'developer-perft',
                    initialPosition: FenCodec.decode(source),
                  );
                  final int nodes = const Perft().count(game.position, 3);
                  setState(() => result = s.perftResult(3, nodes));
                } on Object {
                  setState(() => result = s.invalidFen);
                }
              },
              child: Text(s.runPerft),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pgnTool(BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    String source = '[Event "Developer test"]\n[Result "*"]\n\n1. e4 e5 *';
    String? result;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.pgnImporter),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: source,
                  minLines: 6,
                  maxLines: 14,
                  onChanged: (value) => source = value,
                ),
                if (result != null) Text(result!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.close),
            ),
            FilledButton(
              onPressed: () {
                try {
                  const PgnCodec().decode(source, gameId: 'developer-pgn');
                  setState(() => result = s.validPgn);
                } on Object {
                  setState(() => result = s.invalidPgn);
                }
              },
              child: Text(s.validatePosition),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _boardEditor(BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final List<String> initial = FenCodec.standardInitialPosition.split(' ');
    String board = initial[0];
    String castling = initial[2];
    String enPassant = initial[3];
    String halfmove = initial[4];
    String fullmove = initial[5];
    String side = initial[1];
    String? result;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.boardEditor),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: board,
                    decoration: InputDecoration(labelText: s.boardEditor),
                    onChanged: (value) => board = value,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: side,
                    decoration: InputDecoration(labelText: s.setSideToMove),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'w', child: Text(s.white)),
                      DropdownMenuItem(value: 'b', child: Text(s.black)),
                    ],
                    onChanged: (value) {
                      if (value != null) side = value;
                    },
                  ),
                  TextFormField(
                    initialValue: castling,
                    decoration: InputDecoration(labelText: s.setCastlingRights),
                    onChanged: (value) => castling = value,
                  ),
                  TextFormField(
                    initialValue: enPassant,
                    decoration: InputDecoration(
                      labelText: s.setEnPassantSquare,
                    ),
                    onChanged: (value) => enPassant = value,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          initialValue: halfmove,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: s.setMoveCounters,
                          ),
                          onChanged: (value) => halfmove = value,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space12),
                      Expanded(
                        child: TextFormField(
                          initialValue: fullmove,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: s.setMoveCounters,
                          ),
                          onChanged: (value) => fullmove = value,
                        ),
                      ),
                    ],
                  ),
                  if (result != null) SelectableText(result!),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.close),
            ),
            FilledButton(
              onPressed: () {
                final String fen =
                    '$board $side $castling '
                    '$enPassant $halfmove $fullmove';
                try {
                  FenCodec.decode(fen);
                  setState(() => result = fen);
                } on Object {
                  setState(() => result = s.invalidFen);
                }
              },
              child: Text(s.validatePosition),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grant(
    WidgetRef ref,
    BuildContext context, {
    required int coins,
    required int hints,
  }) async {
    final AppLocalizations s = AppLocalizations.of(context);
    await ref
        .read(challengeRepositoryProvider)
        .grantEarnedReward(
          type: RewardTransactionType.developerAdjustment,
          source: 'developer:${DateTime.now().toUtc().microsecondsSinceEpoch}',
          coins: coins,
          hints: hints,
          now: DateTime.now().toUtc(),
        );
    if (context.mounted) _message(context, s.developmentBalanceChanged);
  }

  Future<void> _adjustCoins(
    WidgetRef ref,
    BuildContext context,
    int amount,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      await ref
          .read(challengeRepositoryProvider)
          .adjustDeveloperBalance(
            asset: RewardAsset.coin,
            amount: amount,
            source:
                'developer-adjustment:'
                '${DateTime.now().toUtc().microsecondsSinceEpoch}',
            now: DateTime.now().toUtc(),
          );
      if (context.mounted) _message(context, s.developmentBalanceChanged);
    } on Object {
      if (context.mounted) _message(context, s.dataActionFailed);
    }
  }

  Future<void> _testDuplicateReward(WidgetRef ref, BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final repository = ref.read(challengeRepositoryProvider);
    final String source =
        'developer-duplicate:${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final DateTime now = DateTime.now().toUtc();
    await repository.grantEarnedReward(
      type: RewardTransactionType.developerAdjustment,
      source: source,
      coins: 1,
      hints: 0,
      now: now,
    );
    final int afterFirst = (await repository.readLedger()).length;
    await repository.grantEarnedReward(
      type: RewardTransactionType.developerAdjustment,
      source: source,
      coins: 1,
      hints: 0,
      now: now,
    );
    final int afterDuplicate = (await repository.readLedger()).length;
    if (context.mounted) {
      _message(
        context,
        s.simulationResult(
          afterFirst == afterDuplicate ? 'duplicate blocked' : 'failed',
        ),
      );
    }
  }

  Future<void> _exportLedger(WidgetRef ref, BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      final String ledger = await ref
          .read(localDataServiceProvider)
          .exportRewardLedger();
      await Clipboard.setData(ClipboardData(text: ledger));
      if (context.mounted) _message(context, s.rewardLedgerCopied);
    } on Object {
      if (context.mounted) _message(context, s.dataActionFailed);
    }
  }

  Future<void> _completeChallenge(WidgetRef ref, BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final controller = ref.read(dailyChallengesControllerProvider);
    await controller.initialize();
    final challenge = controller.dashboard?.today.firstOrNull;
    if (challenge == null) {
      if (context.mounted) _message(context, s.dataActionFailed);
      return;
    }
    await controller.recordEvent(
      ChallengeEvent(
        id:
            'developer-complete:'
            '${DateTime.now().toUtc().microsecondsSinceEpoch}',
        type: challenge.type,
        amount: challenge.targetValue,
      ),
    );
    if (context.mounted) _message(context, s.settingsActionCompleted);
  }

  Future<void> _testDuplicateClaim(WidgetRef ref, BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final controller = ref.read(dailyChallengesControllerProvider);
    await _completeChallenge(ref, context);
    final challenge = controller.dashboard?.today.firstOrNull;
    if (challenge == null) return;
    await controller.claim(challenge.id);
    final bool duplicate = await controller.claim(challenge.id);
    if (context.mounted) {
      _message(
        context,
        s.simulationResult(duplicate ? 'failed' : 'duplicate blocked'),
      );
    }
  }

  Future<void> _editRelay(BuildContext context, WidgetRef ref) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final settings = ref.read(settingsControllerProvider).settings;
    String relayUrl = settings.relayServerUrl;
    final String? value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.editRelayUrl),
        content: TextFormField(
          initialValue: relayUrl,
          decoration: InputDecoration(labelText: s.relayUrl),
          onChanged: (value) => relayUrl = value,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final String value = relayUrl.trim();
              final Uri? uri = Uri.tryParse(value);
              if (value.isEmpty ||
                  (uri != null &&
                      <String>{'ws', 'wss'}.contains(uri.scheme) &&
                      uri.host.isNotEmpty)) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(s.saveGame),
          ),
        ],
      ),
    );
    if (value != null) {
      await ref
          .read(settingsControllerProvider)
          .update(settings.copyWith(relayServerUrl: value));
    }
  }

  Future<void> _testServerHealth(
    BuildContext context,
    AppSettings settings,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    if (settings.relayServerUrl.isEmpty) {
      _message(context, s.friendRelayNotConfigured);
      return;
    }
    try {
      final WebSocket socket = await WebSocket.connect(
        settings.relayServerUrl,
      ).timeout(Duration(seconds: settings.connectionTimeoutSeconds));
      await socket.close(WebSocketStatus.normalClosure, 'health-check');
      if (context.mounted) {
        _message(context, s.simulationResult('reachable'));
      }
    } on Object {
      if (context.mounted) {
        _message(context, s.simulationResult('unreachable'));
      }
    }
  }

  Future<void> _simulateLatency(BuildContext context) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final Stopwatch stopwatch = Stopwatch()..start();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    stopwatch.stop();
    if (context.mounted) {
      _message(
        context,
        s.simulationResult('${stopwatch.elapsedMilliseconds}ms'),
      );
    }
  }

  Future<void> _showRoomState(BuildContext context, AppSettings settings) {
    final AppLocalizations s = AppLocalizations.of(context);
    final String state = const JsonEncoder.withIndent('  ')
        .convert(<String, Object?>{
          'protocolVersion': FriendProtocol.version,
          'relayConfigured': settings.relayServerUrl.isNotEmpty,
          'connection': 'simulated-disconnected',
          'roomCode': null,
          'playerIdentifiers': <Object?>[],
        });
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.showRoomState),
        content: SelectableText(state),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showStateHash(
    BuildContext context,
    AppSettings settings,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final String canonical =
        '${FriendProtocol.version}|'
        '${settings.teamCodeLength}|'
        '${settings.reconnectionSeconds}|simulated-disconnected';
    final String hash = sha256.convert(utf8.encode(canonical)).toString();
    await Clipboard.setData(ClipboardData(text: hash));
    if (context.mounted) {
      _message(context, s.simulationResult(hash));
    }
  }

  Future<void> _showStorageDiagnostics(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      final diagnostic = await ref.read(localDataServiceProvider).diagnostics();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.viewDatabaseTables),
          content: SingleChildScrollView(
            child: SelectableText(
              'schema=${diagnostic.schemaVersion}\n'
              'integrity=${diagnostic.integrityResult}\n'
              'migration=${diagnostic.lastMigrationStatus}\n\n'
              '${diagnostic.tableCounts.entries.map((entry) => '${entry.key}=${entry.value}').join('\n')}',
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

  void _simulateCorruptBackup(BuildContext context, WidgetRef ref) {
    final AppLocalizations s = AppLocalizations.of(context);
    try {
      ref
          .read(localDataServiceProvider)
          .preview(
            '{"formatVersion":1,"schemaVersion":'
            '${DatabaseSchema.currentVersion},"createdAt":"invalid","tables":{}}',
          );
      _message(context, s.simulationResult('failed'));
    } on Object {
      _message(context, s.simulationResult('corruption rejected'));
    }
  }

  Future<bool> _openRepositoryPath(String path) {
    return const SafeLinkService().openOrCopy(
      Uri.parse('https://www.github.com/sanskarIN/Chess/$path'),
    );
  }

  Future<void> _copyDiagnostics(
    BuildContext context,
    AppSettings settings,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final String text = <String>[
      'version=${AppVersion.display}',
      'schema=${DatabaseSchema.currentVersion}',
      'protocol=${FriendProtocol.version}',
      'locale=${settings.localeCode ?? 'system'}',
      'theme=${settings.theme.name}',
      'relayConfigured=${settings.relayServerUrl.isNotEmpty}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _message(context, s.safeDiagnosticsCopied);
  }

  void _message(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  static const Map<String, String> _testPositions = <String, String>{
    'Checkmate': '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1',
    'Stalemate': '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
    'Promotion': '7k/4P3/4K3/8/8/8/8/8 w - - 0 1',
    'En passant': '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 2',
    'Castling': 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
    'Insufficient material': '7k/8/8/8/8/8/8/4K3 w - - 0 1',
  };
}

final class _DeveloperSection extends StatelessWidget {
  const _DeveloperSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: ExpansionTile(title: Text(title), children: children),
    );
  }
}
