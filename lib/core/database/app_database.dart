abstract interface class AppDatabase {
  int get schemaVersion;
  bool get isOpen;

  Future<void> open();
  Future<void> close();
  Future<String?> readSetting(String key);
  Future<void> writeSetting({
    required String key,
    required String valueJson,
    required String valueType,
  });
}
