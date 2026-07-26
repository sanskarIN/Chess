enum AppThemePreference { system, light, dark, highContrast }

enum StartScreenPreference { home, play, challenges, practice, savedGames }

enum BoardThemePreference { classic, forest, ocean, highContrast }

enum PieceThemePreference { classic, modern, accessible }

enum CoordinatePositionPreference { inside, outside, hidden }

enum LegalMoveStylePreference { dotAndRing, square, outline }

enum AnimationSpeedPreference { none, fast, normal, slow }

enum PromotionPreference { ask, autoQueen }

enum ThinkingTimePreference { fast, balanced, strong }

enum HapticIntensityPreference { light, medium, strong }

enum TypedFeatureFlag {
  experimentalAnalysis,
  pseudolocalization,
  debugOverlay,
  performanceOverlay,
  layoutBounds,
  repaintRainbowGuidance,
  stateLogger,
  navigationLogger,
  databaseLogger,
  engineLogger,
  multiplayerLogger,
  localizationKeyViewer,
  accessibilityLabelViewer,
  expandedTextPreview,
  rtlPreview,
}

enum SettingFlag {
  confirmBeforeExit,
  confirmBeforeResignation,
  confirmBeforeSpendingCoins,
  rememberPlayerName,
  boardCoordinates,
  lastMoveHighlight,
  checkHighlight,
  capturedPieceDisplay,
  materialScoreDisplay,
  moveHistoryDisplay,
  reducedMotion,
  fullScreenGame,
  watermarkVisible,
  allowLocalUndo,
  confirmUndo,
  rotateLocalBoard,
  autoFlipBlack,
  showLegalMoves,
  showLastMove,
  hintsEnabled,
  confirmHintSpending,
  autoSave,
  resumeLastGame,
  keepScreenAwake,
  showEvaluation,
  estimatedMaterialAdvantage,
  masterSound,
  music,
  soundEffects,
  moveSound,
  captureSound,
  checkSound,
  checkmateSound,
  clockWarningSound,
  buttonSounds,
  rewardSounds,
  hapticFeedback,
  moveHaptic,
  captureHaptic,
  warningHaptic,
  batterySavingEngine,
  backgroundAnalysis,
  computerThinkingIndicator,
  wifiOnlyWarning,
  networkDiagnostics,
  dailyReminder,
  rewardAnimations,
  coinBalanceDisplay,
  hintBalanceDisplay,
  streakDisplay,
  highContrast,
  largerBoardIndicators,
  strongerLegalMoveMarkers,
  announceMoves,
  announceChecks,
  announceTimerWarnings,
  usePieceNames,
  useAlgebraicNotation,
  hapticAlternatives,
  colorBlindPalette,
  screenReaderBoardMode,
}

final class AppSettings {
  AppSettings({
    required this.theme,
    required this.startScreen,
    required this.boardTheme,
    required this.pieceTheme,
    required this.coordinatePosition,
    required this.legalMoveStyle,
    required this.animationSpeed,
    required this.promotion,
    required this.thinkingTime,
    required this.hapticIntensity,
    required this.defaultGameMode,
    required this.defaultDifficulty,
    required this.defaultPlayerSide,
    required this.defaultTimeControl,
    required this.engineStrengthLimit,
    required this.analysisLines,
    required this.teamCodeLength,
    required this.connectionTimeoutSeconds,
    required this.reconnectionSeconds,
    required this.localeCode,
    required this.defaultPlayerName,
    required this.relayServerUrl,
    required this.shareCodeTemplate,
    required Set<SettingFlag> enabledFlags,
    required Set<TypedFeatureFlag> featureFlags,
    required this.developerOptionsEnabled,
  }) : enabledFlags = Set<SettingFlag>.unmodifiable(enabledFlags),
       featureFlags = Set<TypedFeatureFlag>.unmodifiable(featureFlags);

  factory AppSettings.defaults() {
    return AppSettings(
      theme: AppThemePreference.system,
      startScreen: StartScreenPreference.home,
      boardTheme: BoardThemePreference.classic,
      pieceTheme: PieceThemePreference.classic,
      coordinatePosition: CoordinatePositionPreference.inside,
      legalMoveStyle: LegalMoveStylePreference.dotAndRing,
      animationSpeed: AnimationSpeedPreference.normal,
      promotion: PromotionPreference.ask,
      thinkingTime: ThinkingTimePreference.balanced,
      hapticIntensity: HapticIntensityPreference.medium,
      defaultGameMode: 'computer',
      defaultDifficulty: 'beginner',
      defaultPlayerSide: 'random',
      defaultTimeControl: 'none',
      engineStrengthLimit: 100,
      analysisLines: 1,
      teamCodeLength: 6,
      connectionTimeoutSeconds: 15,
      reconnectionSeconds: 30,
      localeCode: null,
      defaultPlayerName: '',
      relayServerUrl: '',
      shareCodeTemplate: 'Join my Chess-Master game with code {code}.',
      enabledFlags: <SettingFlag>{
        SettingFlag.confirmBeforeExit,
        SettingFlag.confirmBeforeResignation,
        SettingFlag.confirmBeforeSpendingCoins,
        SettingFlag.boardCoordinates,
        SettingFlag.lastMoveHighlight,
        SettingFlag.checkHighlight,
        SettingFlag.capturedPieceDisplay,
        SettingFlag.materialScoreDisplay,
        SettingFlag.moveHistoryDisplay,
        SettingFlag.watermarkVisible,
        SettingFlag.allowLocalUndo,
        SettingFlag.confirmUndo,
        SettingFlag.autoFlipBlack,
        SettingFlag.showLegalMoves,
        SettingFlag.showLastMove,
        SettingFlag.hintsEnabled,
        SettingFlag.confirmHintSpending,
        SettingFlag.autoSave,
        SettingFlag.computerThinkingIndicator,
        SettingFlag.rewardAnimations,
        SettingFlag.coinBalanceDisplay,
        SettingFlag.hintBalanceDisplay,
        SettingFlag.streakDisplay,
        SettingFlag.masterSound,
        SettingFlag.soundEffects,
        SettingFlag.moveSound,
        SettingFlag.captureSound,
        SettingFlag.checkSound,
        SettingFlag.checkmateSound,
        SettingFlag.clockWarningSound,
        SettingFlag.rewardSounds,
        SettingFlag.hapticFeedback,
        SettingFlag.moveHaptic,
        SettingFlag.captureHaptic,
        SettingFlag.warningHaptic,
        SettingFlag.usePieceNames,
        SettingFlag.useAlgebraicNotation,
      },
      featureFlags: const <TypedFeatureFlag>{},
      developerOptionsEnabled: false,
    );
  }

  static const int formatVersion = 1;

  final AppThemePreference theme;
  final StartScreenPreference startScreen;
  final BoardThemePreference boardTheme;
  final PieceThemePreference pieceTheme;
  final CoordinatePositionPreference coordinatePosition;
  final LegalMoveStylePreference legalMoveStyle;
  final AnimationSpeedPreference animationSpeed;
  final PromotionPreference promotion;
  final ThinkingTimePreference thinkingTime;
  final HapticIntensityPreference hapticIntensity;
  final String defaultGameMode;
  final String defaultDifficulty;
  final String defaultPlayerSide;
  final String defaultTimeControl;
  final int engineStrengthLimit;
  final int analysisLines;
  final int teamCodeLength;
  final int connectionTimeoutSeconds;
  final int reconnectionSeconds;
  final String? localeCode;
  final String defaultPlayerName;
  final String relayServerUrl;
  final String shareCodeTemplate;
  final Set<SettingFlag> enabledFlags;
  final Set<TypedFeatureFlag> featureFlags;
  final bool developerOptionsEnabled;

  bool enabled(SettingFlag flag) => enabledFlags.contains(flag);

  bool featureEnabled(TypedFeatureFlag flag) => featureFlags.contains(flag);

  AppSettings copyWith({
    AppThemePreference? theme,
    StartScreenPreference? startScreen,
    BoardThemePreference? boardTheme,
    PieceThemePreference? pieceTheme,
    CoordinatePositionPreference? coordinatePosition,
    LegalMoveStylePreference? legalMoveStyle,
    AnimationSpeedPreference? animationSpeed,
    PromotionPreference? promotion,
    ThinkingTimePreference? thinkingTime,
    HapticIntensityPreference? hapticIntensity,
    String? defaultGameMode,
    String? defaultDifficulty,
    String? defaultPlayerSide,
    String? defaultTimeControl,
    int? engineStrengthLimit,
    int? analysisLines,
    int? teamCodeLength,
    int? connectionTimeoutSeconds,
    int? reconnectionSeconds,
    String? localeCode,
    bool clearLocaleCode = false,
    String? defaultPlayerName,
    String? relayServerUrl,
    String? shareCodeTemplate,
    Set<SettingFlag>? enabledFlags,
    Set<TypedFeatureFlag>? featureFlags,
    bool? developerOptionsEnabled,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      startScreen: startScreen ?? this.startScreen,
      boardTheme: boardTheme ?? this.boardTheme,
      pieceTheme: pieceTheme ?? this.pieceTheme,
      coordinatePosition: coordinatePosition ?? this.coordinatePosition,
      legalMoveStyle: legalMoveStyle ?? this.legalMoveStyle,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      promotion: promotion ?? this.promotion,
      thinkingTime: thinkingTime ?? this.thinkingTime,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      defaultGameMode: defaultGameMode ?? this.defaultGameMode,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      defaultPlayerSide: defaultPlayerSide ?? this.defaultPlayerSide,
      defaultTimeControl: defaultTimeControl ?? this.defaultTimeControl,
      engineStrengthLimit: engineStrengthLimit ?? this.engineStrengthLimit,
      analysisLines: analysisLines ?? this.analysisLines,
      teamCodeLength: teamCodeLength ?? this.teamCodeLength,
      connectionTimeoutSeconds:
          connectionTimeoutSeconds ?? this.connectionTimeoutSeconds,
      reconnectionSeconds: reconnectionSeconds ?? this.reconnectionSeconds,
      localeCode: clearLocaleCode ? null : (localeCode ?? this.localeCode),
      defaultPlayerName: defaultPlayerName ?? this.defaultPlayerName,
      relayServerUrl: relayServerUrl ?? this.relayServerUrl,
      shareCodeTemplate: shareCodeTemplate ?? this.shareCodeTemplate,
      enabledFlags: enabledFlags ?? this.enabledFlags,
      featureFlags: featureFlags ?? this.featureFlags,
      developerOptionsEnabled:
          developerOptionsEnabled ?? this.developerOptionsEnabled,
    );
  }
}
