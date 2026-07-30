import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/app_error.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../l10n/fallback_localizations.dart';
import '../l10n/pseudolocalizer.dart';
import '../l10n/supported_locales.dart';
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
    final SupportedLanguage? explicitLanguage = settings.localeCode == null
        ? null
        : SupportedLanguages.byId(settings.localeCode);

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
        Widget result = child ?? const SizedBox.shrink();
        final MediaQueryData media = MediaQuery.of(context);
        if (settings.enabled(SettingFlag.reducedMotion) ||
            settings.featureEnabled(TypedFeatureFlag.expandedTextPreview)) {
          result = MediaQuery(
            data: media.copyWith(
              disableAnimations: settings.enabled(SettingFlag.reducedMotion),
              textScaler:
                  settings.featureEnabled(TypedFeatureFlag.expandedTextPreview)
                  ? const TextScaler.linear(1.4)
                  : media.textScaler,
            ),
            child: result,
          );
        }
        final SupportedLanguage activeLanguage =
            explicitLanguage ??
            SupportedLanguages.resolveSystem(
              languageCode: Localizations.localeOf(context).languageCode,
              scriptCode: Localizations.localeOf(context).scriptCode,
            );
        if (activeLanguage.isRightToLeft ||
            settings.featureEnabled(TypedFeatureFlag.rtlPreview)) {
          result = Directionality(
            textDirection: TextDirection.rtl,
            child: result,
          );
        }
        if (settings.featureEnabled(TypedFeatureFlag.pseudolocalization)) {
          result = Stack(
            children: <Widget>[
              result,
              IgnorePointer(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Semantics(
                      label: Pseudolocalizer.transform(config.displayName),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            Pseudolocalizer.transform(config.displayName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return result;
      },
      locale: explicitLanguage == null ? null : _locale(explicitLanguage),
      localeListResolutionCallback:
          (List<Locale>? preferredLocales, Iterable<Locale> supportedLocales) {
            if (explicitLanguage != null) return _locale(explicitLanguage);
            for (final Locale locale in preferredLocales ?? const <Locale>[]) {
              final SupportedLanguage language =
                  SupportedLanguages.resolveSystem(
                    languageCode: locale.languageCode,
                    scriptCode: locale.scriptCode,
                  );
              if (language.id != SupportedLanguages.englishId ||
                  locale.languageCode == SupportedLanguages.englishId) {
                return _locale(language);
              }
            }
            return _locale(SupportedLanguages.english);
          },
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackCupertinoLocalizationsDelegate(),
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

Locale _locale(SupportedLanguage language) {
  return Locale.fromSubtags(
    languageCode: language.languageCode,
    scriptCode: language.scriptCode,
  );
}
