import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main() async {
  final File manifestFile = File('assets/engine/manifest.json');
  if (!await manifestFile.exists()) {
    _fail('Engine manifest is missing.');
  }
  final Object? decoded = jsonDecode(await manifestFile.readAsString());
  if (decoded is! Map<String, Object?>) {
    _fail('Engine manifest root must be an object.');
  }
  final Map<String, Object?> manifest = decoded;
  if (manifest['schemaVersion'] != 1) {
    _fail('Unsupported engine manifest schema.');
  }
  final Object? rawSource = manifest['source'];
  if (rawSource is! Map<String, Object?>) {
    _fail('Engine source metadata is missing.');
  }
  final Map<String, Object?> source = rawSource;
  _requireString(source, 'repository');
  final String sourceTag = _requireString(source, 'tag');
  final String sourceCommit = _requireString(source, 'commit');
  if (source['license'] != 'GPL-3.0-only') {
    _fail('Stockfish manifest license must be GPL-3.0-only.');
  }

  final Object? rawBinaries = manifest['binaries'];
  if (rawBinaries is! List<Object?>) {
    _fail('Engine binaries must be a list.');
  }
  const Set<String> allowedAbis = <String>{
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
  };
  final Set<String> declaredPaths = <String>{};
  for (final Object? rawBinary in rawBinaries) {
    if (rawBinary is! Map<String, Object?>) {
      _fail('Every engine binary entry must be an object.');
    }
    final Map<String, Object?> binary = rawBinary;
    final String abi = _requireString(binary, 'abi');
    final String path = _requireString(binary, 'path');
    final String expectedSha = _requireString(binary, 'sha256');
    _requireString(binary, 'archiveUrl');
    _validateSha256(_requireString(binary, 'archiveSha256'));
    if (!allowedAbis.contains(abi)) {
      _fail('Unsupported ABI in engine manifest: $abi');
    }
    if (!path.startsWith('assets/engine/bin/')) {
      _fail('Engine binary is outside the staging directory: $path');
    }
    if (binary['sourceTag'] != sourceTag ||
        binary['sourceCommit'] != sourceCommit) {
      _fail(
        'Engine binary source metadata does not match the manifest source.',
      );
    }
    if (binary['distributionVerified'] != true ||
        binary['debugLoadTested'] != true ||
        binary['releaseLoadTested'] != true) {
      _fail('Engine binary verification flags must all be true.');
    }
    _validateSha256(expectedSha);
    final File file = File(path);
    if (!await file.exists()) {
      _fail('Declared engine binary does not exist: $path');
    }
    final String actualSha = (await sha256.bind(file.openRead()).first)
        .toString();
    if (actualSha != expectedSha) {
      _fail('Engine binary checksum mismatch: $path');
    }
    if (!declaredPaths.add(path)) {
      _fail('Duplicate engine binary path: $path');
    }
  }

  final Directory binaryDirectory = Directory('assets/engine/bin');
  if (await binaryDirectory.exists()) {
    await for (final FileSystemEntity entity in binaryDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        final String path = entity.path.replaceAll(r'\', '/');
        if (!declaredPaths.contains(path)) {
          _fail('Undeclared engine binary found: $path');
        }
      }
    }
  }

  if (declaredPaths.isEmpty) {
    stdout.writeln(
      'Engine manifest valid; no native binary is declared or bundled.',
    );
  } else {
    stdout.writeln(
      'Engine manifest valid; verified ${declaredPaths.length} binaries.',
    );
  }
}

String _requireString(Map<String, Object?> object, String key) {
  final Object? value = object[key];
  if (value is! String || value.isEmpty) {
    _fail('Engine manifest field "$key" must be a non-empty string.');
  }
  return value;
}

void _validateSha256(String value) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    _fail('Invalid SHA-256 value: $value');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exitCode = 1;
  throw FormatException(message);
}
