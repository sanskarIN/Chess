import 'dart:convert';
import 'dart:io';

const String _outputPath = 'docs/release/source_sbom.json';

void main(List<String> arguments) {
  final bool checkOnly = arguments.contains('--check');
  final String generated = _generate();
  final File output = File(_outputPath);
  if (checkOnly) {
    if (!output.existsSync() || output.readAsStringSync() != generated) {
      stderr.writeln(
        'Source SBOM is missing or stale. '
        'Run: dart run tool/generate_source_sbom.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('Source SBOM is current.');
    return;
  }
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(generated);
  stdout.writeln('Generated $_outputPath.');
}

String _generate() {
  final String projectVersion = _projectVersion();
  final List<Map<String, Object?>> components =
      <Map<String, Object?>>[..._dartComponents(), ..._nodeComponents()]
        ..sort((left, right) {
          final int ecosystem = (left['group']! as String).compareTo(
            right['group']! as String,
          );
          if (ecosystem != 0) return ecosystem;
          final int name = (left['name']! as String).compareTo(
            right['name']! as String,
          );
          if (name != 0) return name;
          return (left['version']! as String).compareTo(
            right['version']! as String,
          );
        });
  final Map<String, Object?> bom = <String, Object?>{
    'bomFormat': 'CycloneDX',
    'specVersion': '1.5',
    'serialNumber': 'urn:uuid:6d55c9db-6b60-4d4f-8a61-c8e55a001212',
    'version': 1,
    'metadata': <String, Object?>{
      'component': <String, Object?>{
        'type': 'application',
        'group': 'org.chessmaster',
        'name': 'chess_master',
        'version': projectVersion,
        'licenses': <Object?>[
          <String, Object?>{
            'license': <String, Object?>{'id': 'GPL-3.0-or-later'},
          },
        ],
      },
      'properties': <Object?>[
        <String, Object?>{
          'name': 'chess-master:scope',
          'value': 'source dependency graph; not an APK/AAB artifact inventory',
        },
        <String, Object?>{
          'name': 'chess-master:generator',
          'value': 'tool/generate_source_sbom.dart',
        },
      ],
    },
    'components': components,
  };
  return '${const JsonEncoder.withIndent('  ').convert(bom)}\n';
}

List<Map<String, Object?>> _dartComponents() {
  final String lock = File('pubspec.lock').readAsStringSync();
  final RegExp packageBlock = RegExp(
    r'^  ([A-Za-z0-9_]+):\r?\n(.*?)(?=^  [A-Za-z0-9_]+:\r?\n|^sdks:)',
    multiLine: true,
    dotAll: true,
  );
  final List<Map<String, Object?>> result = <Map<String, Object?>>[];
  for (final RegExpMatch match in packageBlock.allMatches(lock)) {
    final String name = match.group(1)!;
    final String block = match.group(2)!;
    final String version =
        RegExp(
          r'^\s+version:\s+"?([^"\r\n]+)"?\s*$',
          multiLine: true,
        ).firstMatch(block)?.group(1)?.trim() ??
        'sdk';
    final String source =
        RegExp(
          r'^\s+source:\s+([^\r\n]+)$',
          multiLine: true,
        ).firstMatch(block)?.group(1)?.trim() ??
        'unknown';
    final String dependency =
        RegExp(
          r'^\s+dependency:\s+"?([^"\r\n]+)"?\s*$',
          multiLine: true,
        ).firstMatch(block)?.group(1)?.trim() ??
        'transitive';
    result.add(<String, Object?>{
      'type': 'library',
      'group': 'dart',
      'name': name,
      'version': version,
      if (source == 'hosted') 'purl': 'pkg:pub/$name@$version',
      'properties': <Object?>[
        <String, Object?>{'name': 'chess-master:source', 'value': source},
        <String, Object?>{
          'name': 'chess-master:dependency-kind',
          'value': dependency,
        },
        const <String, Object?>{
          'name': 'chess-master:evidence',
          'value': 'pubspec.lock',
        },
      ],
    });
  }
  return result;
}

List<Map<String, Object?>> _nodeComponents() {
  final Map<String, Object?> lock =
      jsonDecode(File('server/package-lock.json').readAsStringSync())
          as Map<String, Object?>;
  final Map<String, Object?> packages =
      lock['packages']! as Map<String, Object?>;
  final List<Map<String, Object?>> result = <Map<String, Object?>>[];
  for (final MapEntry<String, Object?> entry in packages.entries) {
    if (entry.key.isEmpty || entry.value is! Map<String, Object?>) continue;
    final Map<String, Object?> value = entry.value! as Map<String, Object?>;
    final String? version = value['version'] as String?;
    if (version == null) continue;
    final String name = entry.key
        .replaceAll(r'\', '/')
        .split('node_modules/')
        .last;
    final String? license = value['license'] as String?;
    result.add(<String, Object?>{
      'type': 'library',
      'group': 'npm',
      'name': name,
      'version': version,
      'purl': 'pkg:npm/${Uri.encodeComponent(name)}@$version',
      if (license != null)
        'licenses': <Object?>[
          <String, Object?>{
            'license': <String, Object?>{'id': license},
          },
        ],
      'properties': <Object?>[
        <String, Object?>{
          'name': 'chess-master:development-only',
          'value': '${value['dev'] == true}',
        },
        const <String, Object?>{
          'name': 'chess-master:evidence',
          'value': 'server/package-lock.json',
        },
        if (value['integrity'] is String)
          <String, Object?>{
            'name': 'chess-master:npm-integrity',
            'value': value['integrity'],
          },
      ],
    });
  }
  return result;
}

String _projectVersion() {
  final String pubspec = File('pubspec.yaml').readAsStringSync();
  final RegExpMatch? match = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw StateError('pubspec.yaml has no version.');
  }
  return match.group(1)!;
}
