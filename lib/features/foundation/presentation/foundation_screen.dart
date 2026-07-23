import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_config.dart';
import '../../../app/app_version.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../l10n/app_localizations.dart';

final class FoundationScreen extends ConsumerWidget {
  const FoundationScreen({required this.startupError, super.key});

  final AppError? startupError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppConfig config = ref.watch(appConfigProvider);
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool databaseReady =
        startupError == null && (ref.watch(appDatabaseProvider)?.isOpen ?? false);
    final AppError? effectiveError = databaseReady
        ? null
        : startupError ??
              const StorageError(
                code: 'database_not_initialized',
                messageKey: 'errorDatabaseUnavailable',
              );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Semantics(
                container: true,
                label: '${config.displayName}. ${strings.openSourceTagline}',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          label: strings.appTitle,
                          child: ExcludeSemantics(
                            child: Text(
                              '♞',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 72,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          config.displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.openSourceTagline,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          strings.foundationTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(strings.foundationDescription),
                        const SizedBox(height: 20),
                        _StatusPanel(
                          databaseReady: databaseReady,
                          startupError: effectiveError,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${config.creatorWatermark} • v${AppVersion.display}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.databaseReady,
    required this.startupError,
  });

  final bool databaseReady;
  final AppError? startupError;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppError? error = startupError;
    final Color background = databaseReady
        ? colors.primaryContainer
        : colors.errorContainer;
    final Color foreground = databaseReady
        ? colors.onPrimaryContainer
        : colors.onErrorContainer;

    return Semantics(
      liveRegion: !databaseReady,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                databaseReady ? Icons.check_circle_outline : Icons.error_outline,
                color: foreground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      databaseReady
                          ? strings.foundationDatabaseReady
                          : strings.errorDatabaseUnavailable,
                      style: TextStyle(color: foreground),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        strings.diagnosticCode(error.code),
                        style: TextStyle(color: foreground),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
