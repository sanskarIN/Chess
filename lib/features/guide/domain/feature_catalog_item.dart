enum FeatureAvailability {
  available,
  experimental,
  beta,
  planned,
  premiumCandidate,
  underReview,
}

enum FeatureCatalogId {
  computer,
  local,
  friend,
  challenges,
  tutorial,
  practice,
  saved,
  settings,
  localization,
  audio,
  history,
  data,
  premium,
}

final class FeatureCatalogItem {
  const FeatureCatalogItem({required this.id, required this.availability});

  final FeatureCatalogId id;
  final FeatureAvailability availability;
}
