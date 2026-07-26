enum DataImportMode { merge, replace }

final class DataSnapshotPreview {
  const DataSnapshotPreview({
    required this.formatVersion,
    required this.createdAt,
    required this.tableCounts,
  });

  final int formatVersion;
  final DateTime createdAt;
  final Map<String, int> tableCounts;

  int get totalRows => tableCounts.values.fold(0, (sum, count) => sum + count);
}

final class StorageDiagnostic {
  const StorageDiagnostic({
    required this.schemaVersion,
    required this.integrityResult,
    required this.tableCounts,
    required this.lastMigrationStatus,
  });

  final int schemaVersion;
  final String integrityResult;
  final Map<String, int> tableCounts;
  final String lastMigrationStatus;
}

final class DataManagementFailure implements Exception {
  const DataManagementFailure(this.code);

  final String code;

  @override
  String toString() => 'DataManagementFailure($code)';
}
