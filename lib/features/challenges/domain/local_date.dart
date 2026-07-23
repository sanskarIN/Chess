final class LocalDate implements Comparable<LocalDate> {
  const LocalDate._(this.year, this.month, this.day);

  factory LocalDate.fromLocal(DateTime value) {
    final DateTime local = value.isUtc ? value.toLocal() : value;
    return LocalDate._(local.year, local.month, local.day);
  }

  factory LocalDate.parse(String value) {
    final RegExpMatch? match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid local date: $value');
    }
    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    final DateTime normalized = DateTime(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw FormatException('Invalid local date: $value');
    }
    return LocalDate._(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  DateTime get start => DateTime(year, month, day);
  DateTime get nextMidnight => DateTime(year, month, day + 1);
  LocalDate get previousDay =>
      LocalDate.fromLocal(DateTime(year, month, day - 1));

  String get value =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => value;
}
