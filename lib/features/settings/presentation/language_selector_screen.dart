import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/supported_locales.dart';
import '../application/settings_providers.dart';
import '../domain/app_settings.dart';

final class LanguageSelectorScreen extends ConsumerStatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  ConsumerState<LanguageSelectorScreen> createState() =>
      _LanguageSelectorScreenState();
}

final class _LanguageSelectorScreenState
    extends ConsumerState<LanguageSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final controller = ref.watch(settingsControllerProvider);
    final AppSettings settings = controller.settings;
    final List<SupportedLanguage> languages = SupportedLanguages.search(_query);
    final Locale deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale;

    return Scaffold(
      appBar: AppBar(title: Text(strings.languageSettings)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const ValueKey<String>('language-search'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: strings.languageSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey<String>('language-options'),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: <Widget>[
                  _LanguageOption(
                    key: const ValueKey<String>('language-system'),
                    selected: settings.localeCode == null,
                    icon: Icons.settings_suggest_outlined,
                    title: strings.systemLanguage,
                    subtitle: strings.systemLanguageDescription(
                      deviceLocale.toLanguageTag(),
                    ),
                    semanticsLabel: strings.systemLanguage,
                    onTap: controller.busy
                        ? null
                        : () => controller.update(
                            settings.copyWith(clearLocaleCode: true),
                          ),
                  ),
                  const SizedBox(height: 8),
                  if (languages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(strings.noLanguagesFound)),
                    )
                  else
                    for (final SupportedLanguage language in languages) ...[
                      _LanguageOption(
                        key: ValueKey<String>('language-${language.id}'),
                        selected:
                            settings.localeCode != null &&
                            SupportedLanguages.byId(settings.localeCode).id ==
                                language.id,
                        title: language.nativeName,
                        subtitle: language.englishName,
                        detail: strings.localeIdentifier(language.localeTag),
                        semanticsLabel: strings.languageOptionSemantics(
                          language.nativeName,
                          language.englishName,
                        ),
                        titleDirection: language.isRightToLeft
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        onTap: controller.busy
                            ? null
                            : () => controller.update(
                                settings.copyWith(localeCode: language.id),
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.onTap,
    this.detail,
    this.icon,
    this.titleDirection,
    super.key,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String? detail;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final IconData? icon;
  final TextDirection? titleDirection;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Card(
        color: selected ? colors.secondaryContainer : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: icon == null ? null : Icon(icon),
          title: Directionality(
            textDirection: titleDirection ?? Directionality.of(context),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(subtitle),
              if (detail != null)
                Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          trailing: selected
              ? Icon(Icons.check_circle, color: colors.primary)
              : const Icon(Icons.circle_outlined),
          onTap: onTap,
        ),
      ),
    );
  }
}
