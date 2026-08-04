import '../domain/feature_catalog_item.dart';

abstract final class FeatureCatalog {
  static const List<FeatureCatalogItem> items = <FeatureCatalogItem>[
    FeatureCatalogItem(
      id: FeatureCatalogId.computer,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.local,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.friend,
      availability: FeatureAvailability.beta,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.challenges,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.tutorial,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.practice,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.saved,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.settings,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.localization,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.audio,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.history,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.data,
      availability: FeatureAvailability.available,
    ),
    FeatureCatalogItem(
      id: FeatureCatalogId.premium,
      availability: FeatureAvailability.premiumCandidate,
    ),
  ];
}
