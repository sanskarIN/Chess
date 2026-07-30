import 'dart:io';

void main() {
  final List<String> failures = <String>[];
  final List<File> markdownFiles = <File>[
    for (final FileSystemEntity entity in Directory.current.listSync(
      followLinks: false,
    ))
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) entity,
    for (final String directoryPath in <String>['docs', 'server', '.github'])
      if (Directory(directoryPath).existsSync())
        for (final FileSystemEntity entity in Directory(
          directoryPath,
        ).listSync(recursive: true, followLinks: false))
          if (entity is File &&
              entity.path.toLowerCase().endsWith('.md') &&
              !_ignored(entity.path))
            entity,
  ]..sort((left, right) => left.path.compareTo(right.path));

  final RegExp markdownLink = RegExp(r'(?<!!)\[[^\]]*\]\(([^)]+)\)');
  int checkedLinks = 0;
  for (final File source in markdownFiles) {
    final String contents = source.readAsStringSync();
    if (contents.trim().length < 20) {
      failures.add('${source.path} is not substantive.');
    }
    for (final RegExpMatch match in markdownLink.allMatches(contents)) {
      String target = match.group(1)!.trim();
      if (target.startsWith('<') && target.endsWith('>')) {
        target = target.substring(1, target.length - 1);
      }
      final int titleSeparator = target.indexOf(RegExp(r'''\s+["']'''));
      if (titleSeparator >= 0) target = target.substring(0, titleSeparator);
      if (target.isEmpty ||
          target.startsWith('#') ||
          target.startsWith('http://') ||
          target.startsWith('https://') ||
          target.startsWith('mailto:')) {
        continue;
      }
      checkedLinks++;
      final String pathOnly = Uri.decodeComponent(target.split('#').first);
      final String resolved = File(
        '${source.parent.path}${Platform.pathSeparator}$pathOnly',
      ).absolute.path;
      if (!File(resolved).existsSync() && !Directory(resolved).existsSync()) {
        failures.add('${source.path}: broken relative link "$target".');
      }
    }
  }

  const List<String> requiredSets = <String>[
    'docs/users_suggest/README.md',
    'docs/users_suggest/triage.md',
    'docs/users_suggest/feature_proposal_template.md',
    'docs/technologies/README.md',
    'docs/legal/README.md',
    'docs/translations/README.md',
    'docs/upcoming/phases.md',
    'docs/upcoming/next.md',
  ];
  for (final String path in requiredSets) {
    if (!File(path).existsSync()) failures.add('Missing documentation: $path');
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Documentation verification failed:');
    for (final String failure in failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Documentation verification passed: ${markdownFiles.length} Markdown '
    'files and $checkedLinks relative links checked.',
  );
}

bool _ignored(String path) {
  final String normalized = path.replaceAll(r'\', '/');
  return normalized.contains('/.dart_tool/') ||
      normalized.contains('/build/') ||
      normalized.contains('/node_modules/') ||
      normalized.contains('/.git/');
}
