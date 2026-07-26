import 'package:chess_master/core/database/app_database.dart';
import 'package:chess_master/features/settings/data/settings_repository.dart';
import 'package:chess_master/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseSettingsRepository', () {
    test('returns complete defaults when storage is unavailable', () async {
      final DatabaseSettingsRepository repository = DatabaseSettingsRepository(
        null,
      );

      final AppSettings settings = await repository.load();

      expect(settings.theme, AppThemePreference.system);
      expect(settings.startScreen, StartScreenPreference.home);
      expect(settings.teamCodeLength, 6);
      expect(settings.enabled(SettingFlag.masterSound), isTrue);
      expect(settings.enabled(SettingFlag.showLegalMoves), isTrue);
      expect(settings.developerOptionsEnabled, isFalse);
    });

    test('round-trips every typed field and flag', () async {
      final _MemoryDatabase database = _MemoryDatabase();
      final DatabaseSettingsRepository repository = DatabaseSettingsRepository(
        database,
      );
      final AppSettings value = AppSettings.defaults().copyWith(
        theme: AppThemePreference.highContrast,
        startScreen: StartScreenPreference.savedGames,
        boardTheme: BoardThemePreference.ocean,
        pieceTheme: PieceThemePreference.accessible,
        coordinatePosition: CoordinatePositionPreference.outside,
        legalMoveStyle: LegalMoveStylePreference.outline,
        animationSpeed: AnimationSpeedPreference.slow,
        promotion: PromotionPreference.autoQueen,
        thinkingTime: ThinkingTimePreference.strong,
        hapticIntensity: HapticIntensityPreference.strong,
        defaultGameMode: 'friend',
        defaultDifficulty: 'grandmaster',
        defaultPlayerSide: 'black',
        defaultTimeControl: '15+10',
        engineStrengthLimit: 73,
        analysisLines: 4,
        teamCodeLength: 4,
        connectionTimeoutSeconds: 60,
        reconnectionSeconds: 120,
        localeCode: 'hi',
        defaultPlayerName: 'Local player',
        relayServerUrl: 'wss://relay.example.test',
        shareCodeTemplate: 'Code: {code}',
        enabledFlags: SettingFlag.values.toSet(),
        featureFlags: TypedFeatureFlag.values.toSet(),
        developerOptionsEnabled: true,
      );

      await repository.save(value);
      final AppSettings restored = await DatabaseSettingsRepository(
        database,
      ).load();

      expect(restored.theme, value.theme);
      expect(restored.startScreen, value.startScreen);
      expect(restored.boardTheme, value.boardTheme);
      expect(restored.pieceTheme, value.pieceTheme);
      expect(restored.coordinatePosition, value.coordinatePosition);
      expect(restored.legalMoveStyle, value.legalMoveStyle);
      expect(restored.animationSpeed, value.animationSpeed);
      expect(restored.promotion, value.promotion);
      expect(restored.thinkingTime, value.thinkingTime);
      expect(restored.hapticIntensity, value.hapticIntensity);
      expect(restored.defaultGameMode, value.defaultGameMode);
      expect(restored.defaultDifficulty, value.defaultDifficulty);
      expect(restored.defaultPlayerSide, value.defaultPlayerSide);
      expect(restored.defaultTimeControl, value.defaultTimeControl);
      expect(restored.engineStrengthLimit, value.engineStrengthLimit);
      expect(restored.analysisLines, value.analysisLines);
      expect(restored.teamCodeLength, value.teamCodeLength);
      expect(restored.connectionTimeoutSeconds, value.connectionTimeoutSeconds);
      expect(restored.reconnectionSeconds, value.reconnectionSeconds);
      expect(restored.localeCode, value.localeCode);
      expect(restored.defaultPlayerName, value.defaultPlayerName);
      expect(restored.relayServerUrl, value.relayServerUrl);
      expect(restored.shareCodeTemplate, value.shareCodeTemplate);
      expect(restored.enabledFlags, value.enabledFlags);
      expect(restored.featureFlags, value.featureFlags);
      expect(restored.developerOptionsEnabled, isTrue);
      expect(database.lastValueType, 'json');
    });

    test('rejects corrupt and future settings formats safely', () async {
      final _MemoryDatabase database = _MemoryDatabase();
      final DatabaseSettingsRepository repository = DatabaseSettingsRepository(
        database,
      );

      database.values[DatabaseSettingsRepository.settingKey] = '{bad json';
      expect((await repository.load()).theme, AppThemePreference.system);

      database.values[DatabaseSettingsRepository.settingKey] =
          '{"formatVersion":999}';
      expect((await repository.load()).startScreen, StartScreenPreference.home);
    });

    test('reset replaces persisted preferences with defaults', () async {
      final _MemoryDatabase database = _MemoryDatabase();
      final DatabaseSettingsRepository repository = DatabaseSettingsRepository(
        database,
      );
      await repository.save(
        AppSettings.defaults().copyWith(
          theme: AppThemePreference.dark,
          developerOptionsEnabled: true,
        ),
      );

      await repository.reset();

      final AppSettings restored = await repository.load();
      expect(restored.theme, AppThemePreference.system);
      expect(restored.developerOptionsEnabled, isFalse);
    });
  });
}

final class _MemoryDatabase implements AppDatabase {
  final Map<String, String> values = <String, String>{};
  String? lastValueType;
  bool _open = true;

  @override
  bool get isOpen => _open;

  @override
  int get schemaVersion => 3;

  @override
  Future<void> close() async {
    _open = false;
  }

  @override
  Future<void> open() async {
    _open = true;
  }

  @override
  Future<String?> readSetting(String key) async => values[key];

  @override
  Future<void> writeSetting({
    required String key,
    required String valueJson,
    required String valueType,
  }) async {
    values[key] = valueJson;
    lastValueType = valueType;
  }
}
