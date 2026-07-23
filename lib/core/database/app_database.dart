abstract interface class AppDatabase {
  int get schemaVersion;
  bool get isOpen;

  Future<void> open();
  Future<void> close();
}
