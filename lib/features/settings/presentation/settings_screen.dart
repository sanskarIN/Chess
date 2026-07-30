import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/app_router.dart';
import '../../../app/app_version.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/supported_locales.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../application/data_management_providers.dart';
import '../application/settings_controller.dart';
import '../application/settings_providers.dart';
import '../data/safe_link_service.dart';
import '../domain/app_settings.dart';
import 'settings_localizations.dart';

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<SettingFlag> _general = <SettingFlag>[
    SettingFlag.confirmBeforeExit,
    SettingFlag.confirmBeforeResignation,
    SettingFlag.confirmBeforeSpendingCoins,
    SettingFlag.rememberPlayerName,
  ];
  static const List<SettingFlag> _appearance = <SettingFlag>[
    SettingFlag.boardCoordinates,
    SettingFlag.lastMoveHighlight,
    SettingFlag.checkHighlight,
    SettingFlag.capturedPieceDisplay,
    SettingFlag.materialScoreDisplay,
    SettingFlag.moveHistoryDisplay,
    SettingFlag.reducedMotion,
    SettingFlag.fullScreenGame,
    SettingFlag.watermarkVisible,
  ];
  static const List<SettingFlag> _gameplay = <SettingFlag>[
    SettingFlag.allowLocalUndo,
    SettingFlag.confirmUndo,
    SettingFlag.rotateLocalBoard,
    SettingFlag.autoFlipBlack,
    SettingFlag.showLegalMoves,
    SettingFlag.showLastMove,
    SettingFlag.hintsEnabled,
    SettingFlag.confirmHintSpending,
    SettingFlag.autoSave,
    SettingFlag.resumeLastGame,
    SettingFlag.keepScreenAwake,
    SettingFlag.showEvaluation,
    SettingFlag.estimatedMaterialAdvantage,
  ];
  static const List<SettingFlag> _sound = <SettingFlag>[
    SettingFlag.masterSound,
    SettingFlag.music,
    SettingFlag.soundEffects,
    SettingFlag.moveSound,
    SettingFlag.captureSound,
    SettingFlag.checkSound,
    SettingFlag.checkmateSound,
    SettingFlag.clockWarningSound,
    SettingFlag.buttonSounds,
    SettingFlag.rewardSounds,
    SettingFlag.hapticFeedback,
    SettingFlag.moveHaptic,
    SettingFlag.captureHaptic,
    SettingFlag.warningHaptic,
  ];
  static const List<SettingFlag> _computer = <SettingFlag>[
    SettingFlag.batterySavingEngine,
    SettingFlag.backgroundAnalysis,
    SettingFlag.computerThinkingIndicator,
    SettingFlag.showEvaluation,
  ];
  static const List<SettingFlag> _multiplayer = <SettingFlag>[
    SettingFlag.wifiOnlyWarning,
    SettingFlag.networkDiagnostics,
  ];
  static const List<SettingFlag> _challenges = <SettingFlag>[
    SettingFlag.dailyReminder,
    SettingFlag.rewardAnimations,
    SettingFlag.coinBalanceDisplay,
    SettingFlag.hintBalanceDisplay,
    SettingFlag.streakDisplay,
  ];
  static const List<SettingFlag> _accessibility = <SettingFlag>[
    SettingFlag.highContrast,
    SettingFlag.reducedMotion,
    SettingFlag.largerBoardIndicators,
    SettingFlag.strongerLegalMoveMarkers,
    SettingFlag.announceMoves,
    SettingFlag.announceChecks,
    SettingFlag.announceTimerWarnings,
    SettingFlag.usePieceNames,
    SettingFlag.useAlgebraicNotation,
    SettingFlag.hapticAlternatives,
    SettingFlag.colorBlindPalette,
    SettingFlag.screenReaderBoardMode,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations s = AppLocalizations.of(context);
    final SettingsController controller = ref.watch(settingsControllerProvider);
    final AppSettings settings = controller.settings;
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          if (controller.busy) const LinearProgressIndicator(),
          _Section(
            title: s.generalSettings,
            icon: Icons.tune,
            children: <Widget>[
              _Dropdown<AppThemePreference>(
                label: s.theme,
                value: settings.theme,
                values: AppThemePreference.values,
                labelFor: (value) => switch (value) {
                  AppThemePreference.system => s.themeSystem,
                  AppThemePreference.light => s.themeLight,
                  AppThemePreference.dark => s.themeDark,
                  AppThemePreference.highContrast => s.themeHighContrast,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(theme: value)),
              ),
              _Dropdown<StartScreenPreference>(
                label: s.startScreen,
                value: settings.startScreen,
                values: StartScreenPreference.values,
                labelFor: (value) => switch (value) {
                  StartScreenPreference.home => s.startHome,
                  StartScreenPreference.play => s.startPlay,
                  StartScreenPreference.challenges => s.startChallenges,
                  StartScreenPreference.practice => s.startPractice,
                  StartScreenPreference.savedGames => s.startSavedGames,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(startScreen: value)),
              ),
              ..._flags(s, controller, settings, _general),
              ListTile(
                leading: const Icon(Icons.slideshow_outlined),
                title: Text(s.showOnboardingAgain),
                subtitle: Text(s.resetOnboarding),
                onTap: () async {
                  await ref
                      .read(onboardingRepositoryProvider)
                      .setOnboardingCompleted(false);
                  if (context.mounted) {
                    context.go(AppRoutes.onboarding);
                  }
                },
              ),
            ],
          ),
          _Section(
            title: s.appearanceSettings,
            icon: Icons.palette_outlined,
            children: <Widget>[
              _Dropdown<BoardThemePreference>(
                label: s.boardTheme,
                value: settings.boardTheme,
                values: BoardThemePreference.values,
                labelFor: (value) => switch (value) {
                  BoardThemePreference.classic => s.optionClassic,
                  BoardThemePreference.forest => s.optionForest,
                  BoardThemePreference.ocean => s.optionOcean,
                  BoardThemePreference.highContrast => s.themeHighContrast,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(boardTheme: value)),
              ),
              _Dropdown<PieceThemePreference>(
                label: s.pieceTheme,
                value: settings.pieceTheme,
                values: PieceThemePreference.values,
                labelFor: (value) => switch (value) {
                  PieceThemePreference.classic => s.optionClassic,
                  PieceThemePreference.modern => s.optionModern,
                  PieceThemePreference.accessible => s.optionAccessible,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(pieceTheme: value)),
              ),
              _Dropdown<CoordinatePositionPreference>(
                label: s.coordinatePosition,
                value: settings.coordinatePosition,
                values: CoordinatePositionPreference.values,
                labelFor: (value) => switch (value) {
                  CoordinatePositionPreference.inside => s.optionInside,
                  CoordinatePositionPreference.outside => s.optionOutside,
                  CoordinatePositionPreference.hidden => s.optionHidden,
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(coordinatePosition: value),
                ),
              ),
              _Dropdown<LegalMoveStylePreference>(
                label: s.legalMoveStyle,
                value: settings.legalMoveStyle,
                values: LegalMoveStylePreference.values,
                labelFor: (value) => switch (value) {
                  LegalMoveStylePreference.dotAndRing => s.optionDotAndRing,
                  LegalMoveStylePreference.square => s.optionSquare,
                  LegalMoveStylePreference.outline => s.optionOutline,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(legalMoveStyle: value)),
              ),
              _Dropdown<AnimationSpeedPreference>(
                label: s.boardAnimationSpeed,
                value: settings.animationSpeed,
                values: AnimationSpeedPreference.values,
                labelFor: (value) => switch (value) {
                  AnimationSpeedPreference.none => s.optionNone,
                  AnimationSpeedPreference.fast => s.optionFast,
                  AnimationSpeedPreference.normal => s.optionNormal,
                  AnimationSpeedPreference.slow => s.optionSlow,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(animationSpeed: value)),
              ),
              ..._flags(s, controller, settings, _appearance),
              ListTile(
                title: Text(s.textScaleGuidance),
                subtitle: Text(s.watermarkRequiredDescription),
              ),
            ],
          ),
          _Section(
            title: s.gameplaySettings,
            icon: Icons.sports_esports_outlined,
            children: <Widget>[
              _Dropdown<String>(
                label: s.defaultGameMode,
                value: settings.defaultGameMode,
                values: const <String>['computer', 'local', 'friend'],
                labelFor: (value) => switch (value) {
                  'local' => s.localSetupTitle,
                  'friend' => s.friendPlayer,
                  _ => s.computer,
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(defaultGameMode: value),
                ),
              ),
              _Dropdown<String>(
                label: s.computerDifficulty,
                value: settings.defaultDifficulty,
                values: const <String>[
                  'beginner',
                  'intermediate',
                  'expert',
                  'grandmaster',
                ],
                labelFor: (value) => switch (value) {
                  'intermediate' => s.intermediate,
                  'expert' => s.expert,
                  'grandmaster' => s.grandmaster,
                  _ => s.beginner,
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(defaultDifficulty: value),
                ),
              ),
              _Dropdown<String>(
                label: s.defaultPlayerColor,
                value: settings.defaultPlayerSide,
                values: const <String>['white', 'black', 'random'],
                labelFor: (value) => switch (value) {
                  'white' => s.white,
                  'black' => s.black,
                  _ => s.random,
                },
                onChanged: (value) => controller.update(
                  settings.copyWith(defaultPlayerSide: value),
                ),
              ),
              _Dropdown<String>(
                label: s.defaultTimeControl,
                value: settings.defaultTimeControl,
                values: const <String>[
                  'none',
                  '1+0',
                  '3+0',
                  '3+2',
                  '5+0',
                  '10+0',
                  '15+10',
                  '30+0',
                ],
                labelFor: (value) => value == 'none' ? s.noClock : value,
                onChanged: (value) => controller.update(
                  settings.copyWith(defaultTimeControl: value),
                ),
              ),
              SwitchListTile(
                title: Text(s.autoQueenPromotion),
                subtitle: Text(s.askPromotionPiece),
                value: settings.promotion == PromotionPreference.autoQueen,
                onChanged: (value) => controller.update(
                  settings.copyWith(
                    promotion: value
                        ? PromotionPreference.autoQueen
                        : PromotionPreference.ask,
                  ),
                ),
              ),
              ..._flags(s, controller, settings, _gameplay),
            ],
          ),
          _flagSection(
            s,
            controller,
            settings,
            s.soundHapticsSettings,
            Icons.volume_up_outlined,
            _sound,
            footer: _Dropdown<HapticIntensityPreference>(
              label: s.hapticIntensity,
              value: settings.hapticIntensity,
              values: HapticIntensityPreference.values,
              labelFor: (value) => switch (value) {
                HapticIntensityPreference.light => s.optionLight,
                HapticIntensityPreference.medium => s.optionMedium,
                HapticIntensityPreference.strong => s.optionStrong,
              },
              onChanged: (value) =>
                  controller.update(settings.copyWith(hapticIntensity: value)),
            ),
          ),
          _Section(
            title: s.computerSettings,
            icon: Icons.memory_outlined,
            children: <Widget>[
              _Dropdown<ThinkingTimePreference>(
                label: s.thinkingTimePreference,
                value: settings.thinkingTime,
                values: ThinkingTimePreference.values,
                labelFor: (value) => switch (value) {
                  ThinkingTimePreference.fast => s.optionFast,
                  ThinkingTimePreference.balanced => s.optionBalanced,
                  ThinkingTimePreference.strong => s.optionStrong,
                },
                onChanged: (value) =>
                    controller.update(settings.copyWith(thinkingTime: value)),
              ),
              ListTile(
                title: Text(s.engineStrengthLimit),
                subtitle: Slider(
                  value: settings.engineStrengthLimit.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${settings.engineStrengthLimit}',
                  onChanged: (value) => unawaited(
                    controller.update(
                      settings.copyWith(engineStrengthLimit: value.round()),
                    ),
                  ),
                ),
              ),
              _Dropdown<int>(
                label: s.analysisLines,
                value: settings.analysisLines,
                values: const <int>[1, 2, 3, 4, 5],
                labelFor: s.analysisLineCount,
                onChanged: (value) =>
                    controller.update(settings.copyWith(analysisLines: value)),
              ),
              ..._flags(s, controller, settings, _computer),
              ListTile(
                title: Text(s.clearEngineCache),
                subtitle: Text(s.engineActionDescription),
                onTap: () => _message(context, s.settingsActionCompleted),
              ),
              ListTile(
                title: Text(s.restartEngine),
                subtitle: Text(s.engineActionDescription),
                onTap: () => _message(context, s.settingsActionCompleted),
              ),
            ],
          ),
          _Section(
            title: s.multiplayerSettings,
            icon: Icons.hub_outlined,
            children: <Widget>[
              SegmentedButton<int>(
                segments: <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 4, label: Text(s.digitTeamCode(4))),
                  ButtonSegment<int>(value: 6, label: Text(s.digitTeamCode(6))),
                ],
                selected: <int>{settings.teamCodeLength},
                onSelectionChanged: (values) => controller.update(
                  settings.copyWith(teamCodeLength: values.single),
                ),
              ),
              ListTile(
                title: Text(s.connectionTimeout),
                trailing: DropdownButton<int>(
                  value: settings.connectionTimeoutSeconds,
                  items: const <int>[5, 10, 15, 30, 60, 120]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('${value}s'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      controller.update(
                        settings.copyWith(connectionTimeoutSeconds: value),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                title: Text(s.reconnectionDuration),
                trailing: DropdownButton<int>(
                  value: settings.reconnectionSeconds,
                  items: const <int>[5, 15, 30, 60, 120, 300]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('${value}s'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      controller.update(
                        settings.copyWith(reconnectionSeconds: value),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                title: Text(s.preferredSide),
                subtitle: Text(settings.defaultPlayerSide),
                onTap: () => _chooseString(
                  context,
                  title: s.preferredSide,
                  values: const <String>['white', 'black', 'random'],
                  current: settings.defaultPlayerSide,
                  labelFor: (value) => switch (value) {
                    'white' => s.white,
                    'black' => s.black,
                    _ => s.random,
                  },
                  onSelected: (value) => controller.update(
                    settings.copyWith(defaultPlayerSide: value),
                  ),
                ),
              ),
              ListTile(
                title: Text(s.defaultDisplayName),
                subtitle: Text(
                  settings.defaultPlayerName.isEmpty
                      ? s.playerNamePrivacy
                      : settings.defaultPlayerName,
                ),
                onTap: () => _editText(
                  context,
                  title: s.defaultDisplayName,
                  initialValue: settings.defaultPlayerName,
                  helperText: s.playerDisplayNameHint,
                  maxLength: 40,
                  onSaved: (value) => controller.update(
                    settings.copyWith(defaultPlayerName: value.trim()),
                  ),
                ),
              ),
              ListTile(
                title: Text(s.shareCodeTemplate),
                subtitle: Text(settings.shareCodeTemplate),
                onTap: () => _editText(
                  context,
                  title: s.shareCodeTemplate,
                  initialValue: settings.shareCodeTemplate,
                  helperText: s.shareCodeTemplateHint('{code}'),
                  maxLength: 160,
                  validator: (value) =>
                      value.contains('{code}') ? null : s.invalidTeamCode,
                  onSaved: (value) => controller.update(
                    settings.copyWith(shareCodeTemplate: value),
                  ),
                ),
              ),
              ..._flags(s, controller, settings, _multiplayer),
              ListTile(
                title: Text(s.multiplayerPrivacyInformation),
                subtitle: Text(s.multiplayerNetworkDataExplanation),
                leading: const Icon(Icons.privacy_tip_outlined),
              ),
              ListTile(
                title: Text(s.clearRecentOpponents),
                leading: const Icon(Icons.people_outline),
                onTap: () => _confirmAction(
                  context,
                  () =>
                      ref.read(localDataServiceProvider).clearRecentOpponents(),
                ),
              ),
            ],
          ),
          _Section(
            title: s.challengeSettings,
            icon: Icons.calendar_today_outlined,
            children: <Widget>[
              ..._flags(s, controller, settings, _challenges),
              ListTile(
                title: Text(s.challengeRefreshInformation),
                leading: const Icon(Icons.refresh),
              ),
              ListTile(
                title: Text(s.challengeHistory),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.dailyChallenges),
              ),
              ListTile(
                title: Text(s.resetRewardData),
                onTap: () => _confirmAction(
                  context,
                  () => ref.read(localDataServiceProvider).resetRewards(),
                ),
              ),
              ListTile(
                title: Text(s.exportRewardLedger),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.offlineIntegrityExplanation),
                leading: const Icon(Icons.verified_user_outlined),
              ),
            ],
          ),
          _Section(
            title: s.languageSettings,
            icon: Icons.translate,
            children: <Widget>[
              ListTile(
                title: Text(s.language),
                subtitle: Text(
                  settings.localeCode == null
                      ? s.useSystemLanguage
                      : SupportedLanguages.byId(settings.localeCode).nativeName,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.language),
              ),
              ListTile(
                title: Text(s.useSystemLanguage),
                onTap: () =>
                    controller.update(settings.copyWith(clearLocaleCode: true)),
              ),
              ListTile(
                title: Text(s.searchLanguage),
                subtitle: Text(s.previewLanguage),
                onTap: () => context.push(AppRoutes.language),
              ),
              SwitchListTile(
                title: Text(s.rtlPreview),
                value: settings.featureEnabled(TypedFeatureFlag.rtlPreview),
                onChanged: (value) => controller.setFeatureFlag(
                  TypedFeatureFlag.rtlPreview,
                  value,
                ),
              ),
              ListTile(title: Text(s.missingTranslationReporting)),
              ListTile(
                title: Text(s.resetToEnglish),
                subtitle: Text(s.languageAppliesImmediately),
                onTap: () =>
                    controller.update(settings.copyWith(localeCode: 'en')),
              ),
            ],
          ),
          _flagSection(
            s,
            controller,
            settings,
            s.accessibilitySettings,
            Icons.accessibility_new,
            _accessibility,
          ),
          _Section(
            title: s.privacyDataSettings,
            icon: Icons.shield_outlined,
            children: <Widget>[
              ListTile(
                title: Text(s.dataManagement),
                leading: const Icon(Icons.storage_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.dataManagement),
              ),
              ListTile(
                title: Text(s.privacyPolicy),
                onTap: () => _showText(
                  context,
                  s.privacyPolicy,
                  '${s.dataRetentionExplanation}\n\n'
                  '${s.noAccountExplanation}\n\n'
                  '${s.noTrackingExplanation}',
                ),
              ),
              ListTile(
                title: Text(s.termsConditions),
                onTap: () =>
                    _showText(context, s.termsConditions, s.openSourceStatus),
              ),
              ListTile(
                title: Text(s.dataRetentionExplanation),
                onTap: () => _showText(
                  context,
                  s.dataRetentionExplanation,
                  s.dataRetentionExplanation,
                ),
              ),
              ListTile(
                title: Text(s.multiplayerNetworkDataExplanation),
                onTap: () => _showText(
                  context,
                  s.multiplayerSettings,
                  s.multiplayerNetworkDataExplanation,
                ),
              ),
              ListTile(
                title: Text(s.noAccountExplanation),
                onTap: () => _showText(
                  context,
                  s.noAccountExplanation,
                  s.noAccountExplanation,
                ),
              ),
              ListTile(
                title: Text(s.noTrackingExplanation),
                onTap: () => _showText(
                  context,
                  s.noTrackingExplanation,
                  s.noTrackingExplanation,
                ),
              ),
            ],
          ),
          _AboutSection(controller: controller),
          _FollowSection(),
          const SizedBox(height: DesignTokens.space16),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, controller),
            icon: const Icon(Icons.restore),
            label: Text(s.settingsReset),
          ),
        ],
      ),
    );
  }

  List<Widget> _flags(
    AppLocalizations s,
    SettingsController controller,
    AppSettings settings,
    List<SettingFlag> flags,
  ) {
    return flags
        .map((flag) {
          return SwitchListTile(
            title: Text(settingFlagLabel(s, flag)),
            value: settings.enabled(flag),
            onChanged: (value) => controller.setFlag(flag, value),
          );
        })
        .toList(growable: false);
  }

  Widget _flagSection(
    AppLocalizations s,
    SettingsController controller,
    AppSettings settings,
    String title,
    IconData icon,
    List<SettingFlag> flags, {
    Widget? footer,
  }) {
    return _Section(
      title: title,
      icon: icon,
      children: <Widget>[..._flags(s, controller, settings, flags), ?footer],
    );
  }

  Future<void> _chooseString(
    BuildContext context, {
    required String title,
    required List<String> values,
    required String current,
    required String Function(String value) labelFor,
    required Future<void> Function(String value) onSelected,
  }) async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title),
        children: values
            .map(
              (value) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, value),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(labelFor(value))),
                    if (value == current) const Icon(Icons.check),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (selected != null) {
      await onSelected(selected);
    }
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String helperText,
    required int maxLength,
    required Future<void> Function(String value) onSaved,
    String? Function(String value)? validator,
  }) async {
    final AppLocalizations s = AppLocalizations.of(context);
    String editedValue = initialValue;
    String? error;
    final String? value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: initialValue,
            maxLength: maxLength,
            onChanged: (value) => editedValue = value,
            decoration: InputDecoration(
              helperText: helperText,
              errorText: error,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () {
                final String? validation = validator?.call(editedValue);
                if (validation != null) {
                  setState(() => error = validation);
                  return;
                }
                Navigator.pop(dialogContext, editedValue);
              },
              child: Text(s.saveGame),
            ),
          ],
        ),
      ),
    );
    if (value != null) {
      await onSaved(value);
    }
  }

  Future<void> _confirmAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.strongConfirmation),
        content: Text(s.deleteSavedGameDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

  Future<void> _showText(BuildContext context, String title, String body) {
    final AppLocalizations s = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  void _message(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _confirmReset(
    BuildContext context,
    SettingsController controller,
  ) async {
    final AppLocalizations s = AppLocalizations.of(context);
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.settingsReset),
        content: Text(s.settingsResetDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.settingsReset),
          ),
        ],
      ),
    );
    if (result == true) {
      await controller.reset();
    }
  }
}

final class _AboutSection extends ConsumerWidget {
  const _AboutSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations s = AppLocalizations.of(context);
    final String name = ref.watch(appConfigProvider).displayName;
    return _Section(
      title: s.aboutSettings,
      icon: Icons.info_outline,
      children: <Widget>[
        ListTile(title: Text(name), subtitle: Text(s.openSourceStatus)),
        ListTile(
          title: Text(s.currentVersion),
          subtitle: Text(AppVersion.display),
          onTap: () async {
            final bool enabled = await controller.registerVersionTap();
            if (!context.mounted) return;
            final int remaining = controller.remainingDeveloperTaps;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  enabled
                      ? s.developerOptionsEnabledMessage
                      : s.developerStepsAway(remaining),
                ),
              ),
            );
          },
        ),
        ListTile(
          title: Text(s.buildNumber),
          subtitle: Text('${AppVersion.buildNumber}'),
        ),
        ListTile(
          title: Text(s.releaseChannel),
          subtitle: Text(s.developmentChannel),
        ),
        if (controller.settings.developerOptionsEnabled)
          ListTile(
            title: Text(s.developerOptions),
            leading: const Icon(Icons.developer_mode),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.developerOptions),
          )
        else
          ListTile(title: Text(s.tapVersionToUnlock)),
        ListTile(
          title: Text(s.license),
          subtitle: const Text('GPL-3.0-or-later'),
          onTap: () => _showAboutDialog(
            context,
            s.license,
            '${s.copyrightNotice}\n\n'
            '${s.gplSummary}\n\n'
            '${s.noWarrantyNotice}\n\n'
            '${s.sourceCodeNotice}',
          ),
        ),
        ListTile(title: Text(s.creator), subtitle: const Text('Sanskar')),
        ListTile(
          title: Text(s.repository),
          subtitle: const Text('https://www.github.com/sanskarIN/Chess'),
          onTap: () => const SafeLinkService().openOrCopy(
            Uri.parse('https://www.github.com/sanskarIN/Chess'),
          ),
        ),
        ListTile(
          title: Text(s.creatorWatermark),
          subtitle: Text(s.watermarkRequiredDescription),
        ),
        ListTile(
          title: Text(s.technologies),
          subtitle: const Text(
            'Flutter · Dart · Riverpod · SQLite · Stockfish · Node.js',
          ),
          onTap: () => _showAboutDialog(
            context,
            s.technologies,
            'Flutter, Dart, Riverpod, SQLite, Stockfish, Node.js, '
            'TypeScript, and WebSocket.',
          ),
        ),
        ListTile(
          title: Text(s.contributors),
          subtitle: const Text('Sanskar and open-source contributors'),
        ),
        ListTile(
          title: Text(s.thirdPartyLicenses),
          onTap: () => showLicensePage(
            context: context,
            applicationName: name,
            applicationVersion: AppVersion.display,
          ),
        ),
        ListTile(
          title: Text(s.changelog),
          subtitle: Text(AppVersion.display),
          onTap: () => _showAboutDialog(
            context,
            s.changelog,
            s.phaseElevenChangelog(AppVersion.display),
          ),
        ),
        ListTile(
          title: Text(s.featuresCatalog),
          onTap: () => context.push(AppRoutes.features),
        ),
        ListTile(
          title: Text(s.upcomingFeatures),
          onTap: () => context.push(AppRoutes.features),
        ),
        ListTile(
          title: Text(s.supportDetails),
          subtitle: const Text('supportramsandesh@gmail.com'),
          onTap: () => const SafeLinkService().openOrCopy(
            Uri.parse('mailto:supportramsandesh@gmail.com'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAboutDialog(
    BuildContext context,
    String title,
    String body,
  ) {
    final AppLocalizations s = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }
}

final class _FollowSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations s = AppLocalizations.of(context);
    const Map<String, String> links = <String, String>{
      'GitHub': 'https://www.github.com/sanskarIN',
      'YouTube': 'https://youtube.com/@Sanskar-in',
      'LinkedIn': 'https://www.linkedin.com/in/sanskarin',
      'X': 'https://www.x.com/Sanskar_in',
      'Repository': 'https://www.github.com/sanskarIN/Chess',
      'Support': 'mailto:supportramsandesh@gmail.com',
      'Development': 'mailto:sanskarin@outlook.in',
    };
    return _Section(
      title: s.followCreator,
      icon: Icons.link,
      children: links.entries
          .map((entry) {
            return ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                final bool opened = await const SafeLinkService().openOrCopy(
                  Uri.parse(entry.value),
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.linkCopiedFallback)));
                }
              },
            );
          })
          .toList(growable: false),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        children: children,
      ),
    );
  }
}

final class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<T>(
        value: value,
        items: values
            .map(
              (item) =>
                  DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
            )
            .toList(growable: false),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
      ),
    );
  }
}
