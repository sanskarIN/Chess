/// Validates source publication without waiving Android distribution gates.
List<String> validateSourceRelease(Object? raw, String projectVersion) {
  final List<String> failures = <String>[];
  if (raw is! Map<String, Object?>) {
    return <String>['A sourceRelease object is required.'];
  }
  final String versionName = projectVersion.split('+').first;
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(versionName)) {
    failures.add('Stable source release requires a semantic version.');
  }
  if (raw['tag'] != 'v$versionName') {
    failures.add('Source release tag must match the project version.');
  }
  if (raw['channel'] != 'stable' || raw['scope'] != 'source-only') {
    failures.add('This release must be explicitly stable and source-only.');
  }
  if (raw['androidBinariesIncluded'] != false) {
    failures.add(
      'A source-only release must explicitly exclude Android binaries.',
    );
  }
  if (raw['website'] != 'https://sanskarin.github.io') {
    failures.add('Source release must use the canonical creator website.');
  }
  if (raw['notesPath'] != 'docs/release/v$versionName.md') {
    failures.add(
      'Versioned source release notes must match the project version.',
    );
  }
  return failures;
}
