import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/feature_catalog.dart';
import '../domain/feature_catalog_item.dart';

final class FeatureCatalogScreen extends StatefulWidget {
  const FeatureCatalogScreen({super.key});

  @override
  State<FeatureCatalogScreen> createState() => _FeatureCatalogScreenState();
}

final class _FeatureCatalogScreenState extends State<FeatureCatalogScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String query = _query.trim().toLowerCase();
    final List<FeatureCatalogItem> items = FeatureCatalog.items
        .where((FeatureCatalogItem item) {
          return query.isEmpty ||
              _title(strings, item.id).toLowerCase().contains(query) ||
              _body(strings, item.id).toLowerCase().contains(query) ||
              _status(strings, item.availability).toLowerCase().contains(query);
        })
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: Text(strings.featuresCatalog)),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          Text(
            strings.featuresCatalogSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space16),
          TextField(
            decoration: InputDecoration(
              labelText: strings.searchFeatures,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: DesignTokens.space16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space24),
              child: Center(child: Text(strings.noSearchResults)),
            )
          else
            for (final FeatureCatalogItem item in items)
              Card(
                child: ListTile(
                  title: Text(_title(strings, item.id)),
                  subtitle: Text(_body(strings, item.id)),
                  trailing: _StatusChip(
                    label: _status(strings, item.availability),
                    availability: item.availability,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _title(AppLocalizations strings, FeatureCatalogId id) {
    return switch (id) {
      FeatureCatalogId.computer => strings.featureComputerTitle,
      FeatureCatalogId.local => strings.featureLocalTitle,
      FeatureCatalogId.friend => strings.featureFriendTitle,
      FeatureCatalogId.challenges => strings.featureChallengesTitle,
      FeatureCatalogId.tutorial => strings.featureTutorialTitle,
      FeatureCatalogId.practice => strings.featurePracticeTitle,
      FeatureCatalogId.saved => strings.featureSavedTitle,
      FeatureCatalogId.settings => strings.featureSettingsTitle,
      FeatureCatalogId.localization => strings.featureLocalizationTitle,
      FeatureCatalogId.audio => strings.featureAudioTitle,
      FeatureCatalogId.history => strings.featureHistoryTitle,
      FeatureCatalogId.data => strings.featureDataTitle,
      FeatureCatalogId.premium => strings.featurePremiumTitle,
    };
  }

  String _body(AppLocalizations strings, FeatureCatalogId id) {
    return switch (id) {
      FeatureCatalogId.computer => strings.featureComputerBody,
      FeatureCatalogId.local => strings.featureLocalBody,
      FeatureCatalogId.friend => strings.featureFriendBody,
      FeatureCatalogId.challenges => strings.featureChallengesBody,
      FeatureCatalogId.tutorial => strings.featureTutorialBody,
      FeatureCatalogId.practice => strings.featurePracticeBody,
      FeatureCatalogId.saved => strings.featureSavedBody,
      FeatureCatalogId.settings => strings.featureSettingsBody,
      FeatureCatalogId.localization => strings.featureLocalizationBody,
      FeatureCatalogId.audio => strings.featureAudioBody,
      FeatureCatalogId.history => strings.featureHistoryBody,
      FeatureCatalogId.data => strings.featureDataBody,
      FeatureCatalogId.premium => strings.featurePremiumBody,
    };
  }

  String _status(AppLocalizations strings, FeatureAvailability status) {
    return switch (status) {
      FeatureAvailability.available => strings.statusAvailable,
      FeatureAvailability.experimental => strings.statusExperimental,
      FeatureAvailability.beta => strings.statusBeta,
      FeatureAvailability.planned => strings.statusPlanned,
      FeatureAvailability.premiumCandidate => strings.statusPremiumCandidate,
      FeatureAvailability.underReview => strings.statusUnderReview,
    };
  }
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.availability});

  final String label;
  final FeatureAvailability availability;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = switch (availability) {
      FeatureAvailability.available => colors.primaryContainer,
      FeatureAvailability.beta ||
      FeatureAvailability.experimental => colors.tertiaryContainer,
      FeatureAvailability.planned ||
      FeatureAvailability.premiumCandidate ||
      FeatureAvailability.underReview => colors.surfaceContainerHighest,
    };
    return Chip(
      label: Text(label),
      backgroundColor: background,
      visualDensity: VisualDensity.compact,
    );
  }
}
