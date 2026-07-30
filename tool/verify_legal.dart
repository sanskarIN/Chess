import 'dart:convert';
import 'dart:io';

const List<String> _requiredFiles = <String>[
  'LICENSE',
  'COPYRIGHT',
  'NOTICE',
  'THIRD_PARTY_NOTICES.md',
  'PRIVACY.md',
  'TERMS.md',
  'SECURITY.md',
  'CONTRIBUTING.md',
  'CODE_OF_CONDUCT.md',
  'SUPPORT.md',
  'GOVERNANCE.md',
  'AUTHORS.md',
  'CHANGELOG.md',
  'docs/legal/README.md',
  'docs/legal/dependency_audit.md',
  'docs/legal/stockfish_distribution.md',
  'docs/legal/release_legal_checklist.md',
  'docs/legal/privacy_data_map.md',
];

void main() {
  final List<String> failures = <String>[];
  for (final String path in _requiredFiles) {
    final File file = File(path);
    if (!file.existsSync() || file.readAsStringSync().trim().length < 40) {
      failures.add('Required legal/policy file is missing or empty: $path');
    }
  }

  _verifyProjectLicense(failures);
  final int dartPackageCount = _verifyDartPackageLicenses(failures);
  final int nodePackageCount = _verifyNodeLockLicenses(failures);
  _verifyDistributionClaims(failures);

  if (failures.isNotEmpty) {
    stderr.writeln('Legal/source verification failed:');
    for (final String failure in failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Legal/source verification passed: canonical GPL sections present, '
    '${_requiredFiles.length} policy/notice files, $dartPackageCount hosted '
    'Dart package license files, and $nodePackageCount npm lock entries with '
    'license expressions.',
  );
}

void _verifyProjectLicense(List<String> failures) {
  final File licenseFile = File('LICENSE');
  if (!licenseFile.existsSync()) return;
  final String license = licenseFile.readAsStringSync();
  final String normalizedLicense = license.replaceAll(RegExp(r'\s+'), ' ');
  const List<String> requiredPassages = <String>[
    'GNU GENERAL PUBLIC LICENSE',
    'Version 3, 29 June 2007',
    '0. Definitions.',
    '1. Source Code.',
    '2. Basic Permissions.',
    '3. Protecting Users',
    '4. Conveying Verbatim Copies.',
    '5. Conveying Modified Source Versions.',
    '6. Conveying Non-Source Forms.',
    '7. Additional Terms.',
    '8. Termination.',
    '9. Acceptance Not Required',
    '10. Automatic Licensing',
    '11. Patents.',
    '12. No Surrender',
    '13. Use with the GNU Affero',
    '14. Revised Versions',
    '15. Disclaimer of Warranty.',
    '16. Limitation of Liability.',
    '17. Interpretation',
    'END OF TERMS AND CONDITIONS',
    'this is the first time you have received notice of violation',
  ];
  for (final String passage in requiredPassages) {
    if (!normalizedLicense.contains(passage.replaceAll(RegExp(r'\s+'), ' '))) {
      failures.add('LICENSE is missing canonical passage: "$passage".');
    }
  }
}

int _verifyDartPackageLicenses(List<String> failures) {
  final File lockFile = File('pubspec.lock');
  final File configFile = File('.dart_tool/package_config.json');
  if (!lockFile.existsSync()) {
    failures.add('pubspec.lock is missing.');
    return 0;
  }
  if (!configFile.existsSync()) {
    failures.add(
      '.dart_tool/package_config.json is missing; run flutter pub get.',
    );
    return 0;
  }

  final Map<String, Object?> packageConfig =
      jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
  final List<Object?> rawPackages = packageConfig['packages']! as List<Object?>;
  final Map<String, Uri> roots = <String, Uri>{};
  final Uri configUri = configFile.absolute.uri;
  for (final Object? raw in rawPackages) {
    if (raw is! Map<String, Object?> ||
        raw['name'] is! String ||
        raw['rootUri'] is! String) {
      continue;
    }
    final Uri root = Uri.parse(raw['rootUri']! as String);
    roots[raw['name']! as String] = root.isAbsolute
        ? root
        : configUri.resolveUri(root);
  }

  final String lock = lockFile.readAsStringSync();
  final RegExp packageBlock = RegExp(
    r'^  ([A-Za-z0-9_]+):\r?\n(.*?)(?=^  [A-Za-z0-9_]+:\r?\n|^sdks:)',
    multiLine: true,
    dotAll: true,
  );
  int checked = 0;
  for (final RegExpMatch match in packageBlock.allMatches(lock)) {
    final String name = match.group(1)!;
    final String block = match.group(2)!;
    if (!RegExp(r'^\s+source: hosted\s*$', multiLine: true).hasMatch(block)) {
      continue;
    }
    checked++;
    final Uri? root = roots[name];
    if (root == null) {
      failures.add(
        'Hosted Dart package "$name" is absent from package config.',
      );
      continue;
    }
    final Directory directory = Directory.fromUri(root);
    final List<File> candidates = <File>[
      File('${directory.path}${Platform.pathSeparator}LICENSE'),
      File('${directory.path}${Platform.pathSeparator}LICENSE.txt'),
      File('${directory.path}${Platform.pathSeparator}COPYING'),
      File('${directory.path}${Platform.pathSeparator}COPYING.txt'),
    ];
    if (!directory.existsSync() ||
        !candidates.any(
          (file) =>
              file.existsSync() && file.readAsStringSync().trim().isNotEmpty,
        )) {
      failures.add('Hosted Dart package "$name" has no resolved license file.');
    }
  }
  if (checked == 0) {
    failures.add('No hosted Dart packages were discovered in pubspec.lock.');
  }
  return checked;
}

int _verifyNodeLockLicenses(List<String> failures) {
  final File lockFile = File('server/package-lock.json');
  if (!lockFile.existsSync()) {
    failures.add('server/package-lock.json is missing.');
    return 0;
  }
  final Map<String, Object?> lock =
      jsonDecode(lockFile.readAsStringSync()) as Map<String, Object?>;
  if (lock['lockfileVersion'] != 3) {
    failures.add('Node lockfile must use lockfileVersion 3.');
  }
  final Map<String, Object?> packages =
      lock['packages']! as Map<String, Object?>;
  int checked = 0;
  for (final MapEntry<String, Object?> entry in packages.entries) {
    if (entry.key.isEmpty) continue;
    checked++;
    final Object? raw = entry.value;
    if (raw is! Map<String, Object?> ||
        raw['license'] is! String ||
        (raw['license']! as String).trim().isEmpty) {
      failures.add('npm lock entry "${entry.key}" has no license expression.');
    }
    if (raw is Map<String, Object?> &&
        (raw['resolved'] is! String || raw['integrity'] is! String)) {
      failures.add(
        'npm lock entry "${entry.key}" lacks resolved/integrity evidence.',
      );
    }
  }
  if (checked == 0) {
    failures.add('No npm packages were discovered in the relay lockfile.');
  }
  return checked;
}

void _verifyDistributionClaims(List<String> failures) {
  final String notice = File('NOTICE').readAsStringSync();
  final String thirdParty = File('THIRD_PARTY_NOTICES.md').readAsStringSync();
  final String stockfish = File(
    'docs/legal/stockfish_distribution.md',
  ).readAsStringSync();
  if (!notice.contains('does not contain or distribute a Stockfish') ||
      !thirdParty.contains('No Stockfish binary') ||
      !stockfish.contains('do **not** include a Stockfish executable')) {
    failures.add(
      'Stockfish non-bundling and future distribution boundary is incomplete.',
    );
  }
  final String pubspec = File('pubspec.yaml').readAsStringSync();
  if (!pubspec.contains('publish_to: none')) {
    failures.add('pubspec.yaml must remain non-publishable by default.');
  }
}
