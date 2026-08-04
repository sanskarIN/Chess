import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const List<String> _requiredDocuments = <String>[
  'docs/release/README.md',
  'docs/release/release_checklist.md',
  'docs/release/test_matrix.md',
  'docs/release/android_build.md',
  'docs/release/accessibility_review.md',
  'docs/release/performance_review.md',
  'docs/release/security_review.md',
  'docs/release/known_limitations.md',
  'docs/release/reproducible_builds.md',
  'docs/release/signing_and_provenance.md',
  'docs/release/store_submission.md',
  'docs/release/rollback_and_incident.md',
  'docs/release/release_notes_template.md',
  'docs/release/release_status.json',
  'docs/release/source_sbom.json',
];

const Set<String> _requiredGateIds = <String>{
  'formatting',
  'analysis',
  'unit_widget_tests',
  'integration_tests',
  'server_tests',
  'chess_domain',
  'localization',
  'license_review',
  'documentation',
  'security_source_review',
  'accessibility_automated',
  'accessibility_device',
  'performance_source_review',
  'performance_device',
  'android_debug_build',
  'stockfish_binary',
  'native_translation_review',
  'release_signing',
  'store_submission',
  'human_legal_approval',
};

const Set<String> _mustPass = <String>{
  'formatting',
  'analysis',
  'unit_widget_tests',
  'integration_tests',
  'server_tests',
  'chess_domain',
  'localization',
  'license_review',
  'documentation',
  'security_source_review',
  'accessibility_automated',
  'performance_source_review',
};

const Set<String> _mustRemainExternalUntilApproved = <String>{
  'accessibility_device',
  'performance_device',
  'native_translation_review',
  'release_signing',
  'store_submission',
  'human_legal_approval',
};

void main() {
  final List<String> failures = <String>[];
  for (final String path in _requiredDocuments) {
    final File file = File(path);
    if (!file.existsSync() || file.readAsStringSync().trim().length < 40) {
      failures.add('Required release artifact is missing or empty: $path');
    }
  }
  if (failures.isNotEmpty) {
    _finish(failures, 0);
  }

  final String expectedVersion = _projectVersion(failures);
  _verifyAppVersion(expectedVersion, failures);
  final int components = _verifySbom(expectedVersion, failures);
  _verifyReleaseStatus(expectedVersion, failures);

  _finish(failures, components);
}

void _verifyReleaseStatus(String expectedVersion, List<String> failures) {
  final Map<String, Object?> status = _jsonObject(
    'docs/release/release_status.json',
    failures,
  );
  if (status['schemaVersion'] != 1) {
    failures.add('release_status.json schemaVersion must be 1.');
  }
  if (status['releaseVersion'] != expectedVersion) {
    failures.add(
      'Release status version does not match pubspec: '
      '${status['releaseVersion']} != $expectedVersion.',
    );
  }
  final Object? rawGates = status['gates'];
  if (rawGates is! List<Object?>) {
    failures.add('Release status gates must be a list.');
    return;
  }
  final Map<String, Map<String, Object?>> gates =
      <String, Map<String, Object?>>{};
  const Set<String> allowedStatuses = <String>{
    'passed',
    'blocked',
    'external',
    'not_applicable',
  };
  for (final Object? raw in rawGates) {
    if (raw is! Map<String, Object?> || raw['id'] is! String) {
      failures.add('Every release gate must be an object with a string id.');
      continue;
    }
    final String id = raw['id']! as String;
    if (gates.containsKey(id)) {
      failures.add('Duplicate release gate: $id.');
      continue;
    }
    gates[id] = raw;
    final String? gateStatus = raw['status'] as String?;
    if (!allowedStatuses.contains(gateStatus)) {
      failures.add('Gate "$id" has invalid status "$gateStatus".');
    }
    final Object? evidence = raw['evidence'];
    if (evidence is! List<Object?> ||
        evidence.isEmpty ||
        evidence.any((item) => item is! String || item.trim().isEmpty)) {
      failures.add('Gate "$id" must contain non-empty string evidence.');
    }
    if ((gateStatus == 'blocked' || gateStatus == 'external') &&
        (raw['details'] is! String ||
            (raw['details']! as String).trim().length < 20)) {
      failures.add('Gate "$id" requires substantive blocker/external details.');
    }
  }
  final Set<String> actualIds = gates.keys.toSet();
  if (actualIds.difference(_requiredGateIds).isNotEmpty ||
      _requiredGateIds.difference(actualIds).isNotEmpty) {
    failures.add(
      'Release gate IDs differ. Missing: '
      '${_requiredGateIds.difference(actualIds)}; extra: '
      '${actualIds.difference(_requiredGateIds)}.',
    );
  }
  for (final String id in _mustPass) {
    if (gates[id]?['status'] != 'passed') {
      failures.add('Source gate "$id" must pass before Phase 12 completion.');
    }
  }
  for (final String id in _mustRemainExternalUntilApproved) {
    if (gates[id]?['status'] != 'external') {
      failures.add('Unapproved human/device gate "$id" must remain external.');
    }
  }

  final Map<String, Object?>? android = gates['android_debug_build'];
  if (android != null &&
      android['status'] != 'passed' &&
      android['status'] != 'blocked') {
    failures.add('Android debug build must be passed or truthfully blocked.');
  }
  if (android?['status'] == 'passed') {
    final String? artifact = android?['artifact'] as String?;
    final String? sha256 = android?['sha256'] as String?;
    final bool retained = android?['artifactRetainedInRepository'] == true;
    if (artifact == null ||
        sha256 == null ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      failures.add(
        'A passed Android build requires an artifact path and SHA-256.',
      );
    } else {
      final File artifactFile = File(artifact);
      if (retained && !artifactFile.existsSync()) {
        failures.add(
          'The retained Android artifact does not exist: $artifact.',
        );
      } else if (artifactFile.existsSync()) {
        final String actual = digestBytes(artifactFile.readAsBytesSync());
        if (actual != sha256) {
          failures.add('Android artifact SHA-256 does not match $artifact.');
        }
      }
    }
  }

  final Map<String, Object?> engineManifest = _jsonObject(
    'assets/engine/manifest.json',
    failures,
  );
  final Object? binaries = engineManifest['binaries'];
  if (binaries is List<Object?> &&
      binaries.isEmpty &&
      gates['stockfish_binary']?['status'] != 'not_applicable') {
    failures.add(
      'Stockfish binary gate must be not_applicable when none is bundled.',
    );
  }

  final bool ready = status['readyForDistribution'] == true;
  final bool hasOpenGate = gates.values.any(
    (gate) => gate['status'] == 'blocked' || gate['status'] == 'external',
  );
  if (ready && hasOpenGate) {
    failures.add(
      'readyForDistribution cannot be true while a gate is blocked/external.',
    );
  }
  if (!hasOpenGate && !ready) {
    failures.add(
      'readyForDistribution is false even though no open gate is recorded.',
    );
  }
}

String digestBytes(List<int> bytes) => sha256.convert(bytes).toString();

int _verifySbom(String expectedVersion, List<String> failures) {
  final Map<String, Object?> sbom = _jsonObject(
    'docs/release/source_sbom.json',
    failures,
  );
  if (sbom['bomFormat'] != 'CycloneDX' || sbom['specVersion'] != '1.5') {
    failures.add('Source SBOM must declare CycloneDX 1.5.');
  }
  final Object? rawMetadata = sbom['metadata'];
  if (rawMetadata is! Map<String, Object?> ||
      rawMetadata['component'] is! Map<String, Object?>) {
    failures.add('Source SBOM metadata/component is missing.');
  } else {
    final Map<String, Object?> component =
        rawMetadata['component']! as Map<String, Object?>;
    if (component['name'] != 'chess_master' ||
        component['version'] != expectedVersion) {
      failures.add('Source SBOM root component/version is incorrect.');
    }
  }
  final Object? rawComponents = sbom['components'];
  if (rawComponents is! List<Object?> || rawComponents.length < 100) {
    failures.add('Source SBOM must inventory the complete locked graph.');
    return rawComponents is List<Object?> ? rawComponents.length : 0;
  }
  final Set<String> identities = <String>{};
  for (final Object? raw in rawComponents) {
    if (raw is! Map<String, Object?> ||
        raw['group'] is! String ||
        raw['name'] is! String ||
        raw['version'] is! String) {
      failures.add('Every SBOM component needs group, name, and version.');
      continue;
    }
    final String identity = '${raw['group']}:${raw['name']}:${raw['version']}';
    if (!identities.add(identity)) {
      failures.add('Duplicate SBOM component: $identity.');
    }
  }
  return rawComponents.length;
}

String _projectVersion(List<String> failures) {
  final String pubspec = File('pubspec.yaml').readAsStringSync();
  final RegExpMatch? match = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    failures.add('pubspec.yaml has no version.');
    return '';
  }
  return match.group(1)!;
}

void _verifyAppVersion(String expectedVersion, List<String> failures) {
  final String source = File('lib/app/app_version.dart').readAsStringSync();
  final List<String> parts = expectedVersion.split('+');
  if (parts.length != 2 ||
      !source.contains("name = '${parts[0]}'") ||
      !source.contains('buildNumber = ${parts[1]}')) {
    failures.add('AppVersion does not match pubspec version $expectedVersion.');
  }
}

Map<String, Object?> _jsonObject(String path, List<String> failures) {
  try {
    final Object? decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is Map<String, Object?>) return decoded;
  } on Object catch (error) {
    failures.add('$path is not valid JSON: ${error.runtimeType}.');
    return <String, Object?>{};
  }
  failures.add('$path root must be a JSON object.');
  return <String, Object?>{};
}

Never _finish(List<String> failures, int components) {
  if (failures.isNotEmpty) {
    stderr.writeln('Release readiness verification failed:');
    for (final String failure in failures) {
      stderr.writeln('  - $failure');
    }
    exit(1);
  }
  stdout.writeln(
    'Release readiness verification passed: ${_requiredDocuments.length} '
    'artifacts, ${_requiredGateIds.length} gates, and $components source '
    'dependencies; '
    'distribution remains governed by recorded external/blocked gates.',
  );
  exit(0);
}
