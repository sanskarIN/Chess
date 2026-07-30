import 'package:intl/intl.dart';

import 'supported_locales.dart';

final class LocaleFormatting {
  const LocaleFormatting(this.language);

  final SupportedLanguage language;

  String formatInteger(int value) => _formatWithLocale(
    (locale) => NumberFormat.decimalPattern(locale).format(value),
    lastResort: value.toString,
  );

  String formatDecimal(num value) => _formatWithLocale(
    (locale) => NumberFormat.decimalPattern(locale).format(value),
    lastResort: value.toString,
  );

  String formatDate(DateTime value) => _formatWithLocale(
    (locale) => DateFormat.yMMMMd(locale).format(value),
    lastResort: () =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}',
  );

  String formatDuration(Duration value) {
    final int hours = value.inHours;
    final int minutes = value.inMinutes.remainder(60);
    final int seconds = value.inSeconds.remainder(60);
    final List<String> fields = <String>[
      if (hours > 0) '${formatInteger(hours)}h',
      if (hours > 0 || minutes > 0) '${formatInteger(minutes)}m',
      '${formatInteger(seconds)}s',
    ];
    return fields.join(' ');
  }

  String formatRelativeDate(DateTime value, DateTime now) {
    // Relative labels belong in ARB messages. Until a translated label is
    // provided by the caller, a locale-aware absolute date is safer than
    // inserting an English-only word into another language.
    return formatDate(value);
  }

  String _formatWithLocale(
    String Function(String locale) formatter, {
    required String Function() lastResort,
  }) {
    try {
      final String formatted = formatter(language.formattingLocale);
      if (formatted.isNotEmpty) return formatted;
    } on Object {
      // Try the documented English fallback below.
    }
    try {
      final String formatted = formatter('en');
      if (formatted.isNotEmpty) return formatted;
    } on Object {
      // A deterministic non-empty representation is the final safeguard.
    }
    return lastResort();
  }
}
