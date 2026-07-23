import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (Ref ref) => AppConfig.fromEnvironment(),
);

final class AppConfig {
  const AppConfig({
    required this.displayName,
    required this.creatorWatermark,
    required this.repositoryUrl,
    required this.environment,
    this.defaultRelayUrl,
  });

  factory AppConfig.fromEnvironment() {
    const String relayUrl = String.fromEnvironment('CHESS_MASTER_RELAY_URL');

    return AppConfig(
      displayName: const String.fromEnvironment(
        'CHESS_MASTER_APP_NAME',
        defaultValue: 'Chess-Master',
      ),
      creatorWatermark: 'Made by the Sanskar',
      repositoryUrl: Uri.parse('https://www.github.com/sanskarIN/Chess'),
      environment: const String.fromEnvironment(
        'CHESS_MASTER_ENVIRONMENT',
        defaultValue: 'development',
      ),
      defaultRelayUrl: relayUrl.isEmpty ? null : Uri.tryParse(relayUrl),
    );
  }

  final String displayName;
  final String creatorWatermark;
  final Uri repositoryUrl;
  final String environment;
  final Uri? defaultRelayUrl;
}
