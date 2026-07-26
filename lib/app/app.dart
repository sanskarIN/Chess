import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/app_error.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import 'app_config.dart';
import 'app_router.dart';
import 'app_theme.dart';

final class ChessMasterApp extends ConsumerStatefulWidget {
  const ChessMasterApp({super.key, this.startupError});

  final AppError? startupError;

  @override
  ConsumerState<ChessMasterApp> createState() => _ChessMasterAppState();
}

final class _ChessMasterAppState extends ConsumerState<ChessMasterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(startupError: widget.startupError);
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig config = ref.watch(appConfigProvider);
    final AppSettings settings = ref.watch(
      settingsControllerProvider.select((controller) => controller.settings),
    );
    final bool forceHighContrast =
        settings.theme == AppThemePreference.highContrast ||
        settings.enabled(SettingFlag.highContrast);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => config.displayName,
      routerConfig: _router,
      theme: forceHighContrast ? AppTheme.highContrast() : AppTheme.light(),
      darkTheme: AppTheme.dark(),
      highContrastTheme: AppTheme.highContrast(),
      highContrastDarkTheme: AppTheme.dark(),
      themeMode: switch (settings.theme) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light ||
        AppThemePreference.highContrast => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      },
      builder: (BuildContext context, Widget? child) {
        if (!settings.enabled(SettingFlag.reducedMotion)) {
          return child ?? const SizedBox.shrink();
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: settings.localeCode == null ? null : Locale(settings.localeCode!),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
