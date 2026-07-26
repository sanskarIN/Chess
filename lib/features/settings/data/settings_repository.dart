import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<void> reset();
}

final class DatabaseSettingsRepository implements SettingsRepository {
  DatabaseSettingsRepository(this._database);

  static const String settingKey = 'app_settings_v1';

  final AppDatabase? _database;
  AppSettings? _memory;

  @override
  Future<AppSettings> load() async {
    final AppDatabase? database = _database;
    if (database == null || !database.isOpen) {
      return _memory ??= AppSettings.defaults();
    }
    final String? source = await database.readSetting(settingKey);
    if (source == null) {
      return AppSettings.defaults();
    }
    try {
      return _decode(source);
    } on Object {
      return AppSettings.defaults();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    _memory = settings;
    final AppDatabase? database = _database;
    if (database == null || !database.isOpen) {
      return;
    }
    await database.writeSetting(
      key: settingKey,
      valueJson: _encode(settings),
      valueType: 'json',
    );
  }

  @override
  Future<void> reset() => save(AppSettings.defaults());

  String _encode(AppSettings value) {
    return jsonEncode(<String, Object?>{
      'formatVersion': AppSettings.formatVersion,
      'theme': value.theme.name,
      'startScreen': value.startScreen.name,
      'boardTheme': value.boardTheme.name,
      'pieceTheme': value.pieceTheme.name,
      'coordinatePosition': value.coordinatePosition.name,
      'legalMoveStyle': value.legalMoveStyle.name,
      'animationSpeed': value.animationSpeed.name,
      'promotion': value.promotion.name,
      'thinkingTime': value.thinkingTime.name,
      'hapticIntensity': value.hapticIntensity.name,
      'defaultGameMode': value.defaultGameMode,
      'defaultDifficulty': value.defaultDifficulty,
      'defaultPlayerSide': value.defaultPlayerSide,
      'defaultTimeControl': value.defaultTimeControl,
      'engineStrengthLimit': value.engineStrengthLimit,
      'analysisLines': value.analysisLines,
      'teamCodeLength': value.teamCodeLength,
      'connectionTimeoutSeconds': value.connectionTimeoutSeconds,
      'reconnectionSeconds': value.reconnectionSeconds,
      'localeCode': value.localeCode,
      'defaultPlayerName': value.defaultPlayerName,
      'relayServerUrl': value.relayServerUrl,
      'shareCodeTemplate': value.shareCodeTemplate,
      'enabledFlags': value.enabledFlags.map((value) => value.name).toList(),
      'featureFlags': value.featureFlags.map((value) => value.name).toList(),
      'developerOptionsEnabled': value.developerOptionsEnabled,
    });
  }

  AppSettings _decode(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> ||
        decoded['formatVersion'] != AppSettings.formatVersion) {
      throw const FormatException('Unsupported settings format.');
    }
    final AppSettings defaults = AppSettings.defaults();
    return AppSettings(
      theme: _enum(decoded, 'theme', AppThemePreference.values, defaults.theme),
      startScreen: _enum(
        decoded,
        'startScreen',
        StartScreenPreference.values,
        defaults.startScreen,
      ),
      boardTheme: _enum(
        decoded,
        'boardTheme',
        BoardThemePreference.values,
        defaults.boardTheme,
      ),
      pieceTheme: _enum(
        decoded,
        'pieceTheme',
        PieceThemePreference.values,
        defaults.pieceTheme,
      ),
      coordinatePosition: _enum(
        decoded,
        'coordinatePosition',
        CoordinatePositionPreference.values,
        defaults.coordinatePosition,
      ),
      legalMoveStyle: _enum(
        decoded,
        'legalMoveStyle',
        LegalMoveStylePreference.values,
        defaults.legalMoveStyle,
      ),
      animationSpeed: _enum(
        decoded,
        'animationSpeed',
        AnimationSpeedPreference.values,
        defaults.animationSpeed,
      ),
      promotion: _enum(
        decoded,
        'promotion',
        PromotionPreference.values,
        defaults.promotion,
      ),
      thinkingTime: _enum(
        decoded,
        'thinkingTime',
        ThinkingTimePreference.values,
        defaults.thinkingTime,
      ),
      hapticIntensity: _enum(
        decoded,
        'hapticIntensity',
        HapticIntensityPreference.values,
        defaults.hapticIntensity,
      ),
      defaultGameMode: _safeString(
        decoded['defaultGameMode'],
        defaults.defaultGameMode,
      ),
      defaultDifficulty: _safeString(
        decoded['defaultDifficulty'],
        defaults.defaultDifficulty,
      ),
      defaultPlayerSide: _safeString(
        decoded['defaultPlayerSide'],
        defaults.defaultPlayerSide,
      ),
      defaultTimeControl: _safeString(
        decoded['defaultTimeControl'],
        defaults.defaultTimeControl,
      ),
      engineStrengthLimit: _boundedInt(
        decoded['engineStrengthLimit'],
        1,
        100,
        defaults.engineStrengthLimit,
      ),
      analysisLines: _boundedInt(
        decoded['analysisLines'],
        1,
        5,
        defaults.analysisLines,
      ),
      teamCodeLength: decoded['teamCodeLength'] == 4 ? 4 : 6,
      connectionTimeoutSeconds: _boundedInt(
        decoded['connectionTimeoutSeconds'],
        5,
        120,
        defaults.connectionTimeoutSeconds,
      ),
      reconnectionSeconds: _boundedInt(
        decoded['reconnectionSeconds'],
        5,
        300,
        defaults.reconnectionSeconds,
      ),
      localeCode: decoded['localeCode'] as String?,
      defaultPlayerName: _safeString(decoded['defaultPlayerName'], ''),
      relayServerUrl: _safeString(decoded['relayServerUrl'], ''),
      shareCodeTemplate: _safeString(
        decoded['shareCodeTemplate'],
        defaults.shareCodeTemplate,
      ),
      enabledFlags: _enumSet(
        decoded['enabledFlags'],
        SettingFlag.values,
        defaults.enabledFlags,
      ),
      featureFlags: _enumSet(
        decoded['featureFlags'],
        TypedFeatureFlag.values,
        defaults.featureFlags,
      ),
      developerOptionsEnabled: decoded['developerOptionsEnabled'] == true,
    );
  }

  T _enum<T extends Enum>(
    Map<String, Object?> source,
    String key,
    List<T> values,
    T fallback,
  ) {
    final Object? raw = source[key];
    return values.where((T value) => value.name == raw).firstOrNull ?? fallback;
  }

  Set<T> _enumSet<T extends Enum>(
    Object? raw,
    List<T> values,
    Set<T> fallback,
  ) {
    if (raw is! List<Object?>) {
      return fallback;
    }
    final Set<String> names = raw.whereType<String>().toSet();
    return values.where((T value) => names.contains(value.name)).toSet();
  }

  int _boundedInt(Object? raw, int min, int max, int fallback) {
    return raw is int && raw >= min && raw <= max ? raw : fallback;
  }

  String _safeString(Object? raw, String fallback) {
    return raw is String && raw.length <= 500 ? raw : fallback;
  }
}
