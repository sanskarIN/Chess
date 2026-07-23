enum TeamCodeLength {
  four(4),
  six(6);

  const TeamCodeLength(this.digits);

  final int digits;
}

final class TeamCode {
  const TeamCode._(this.value);

  factory TeamCode.parse(String input) {
    final String normalized = input.trim();
    if (!RegExp(r'^(?:[0-9]{4}|[0-9]{6})$').hasMatch(normalized)) {
      throw const FormatException(
        'A team code must contain exactly four or six digits.',
      );
    }
    return TeamCode._(normalized);
  }

  static TeamCode? tryParse(String input) {
    try {
      return TeamCode.parse(input);
    } on FormatException {
      return null;
    }
  }

  final String value;

  TeamCodeLength get length =>
      value.length == 4 ? TeamCodeLength.four : TeamCodeLength.six;

  String get redacted => '••${value.substring(value.length - 2)}';

  @override
  bool operator ==(Object other) => other is TeamCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
