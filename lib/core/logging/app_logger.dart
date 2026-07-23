import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AppLogger> appLoggerProvider = Provider<AppLogger>(
  (Ref ref) => AppLogger(),
);

enum LogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.value);

  final int value;
}

final class AppLogger {
  AppLogger({
    DateTime Function()? clock,
    void Function(LogRecord record)? sink,
  }) : _clock = clock ?? DateTime.now,
       _sink = sink;

  static const Set<String> _sensitiveFieldNames = <String>{
    'authorization',
    'cookie',
    'email',
    'ip',
    'name',
    'playerName',
    'roomCode',
    'teamCode',
    'token',
  };

  final DateTime Function() _clock;
  final void Function(LogRecord record)? _sink;

  void debug(String event, {Map<String, Object?> fields = const {}}) {
    _write(LogLevel.debug, event, fields: fields);
  }

  void info(String event, {Map<String, Object?> fields = const {}}) {
    _write(LogLevel.info, event, fields: fields);
  }

  void warning(
    String event, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      LogLevel.warning,
      event,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String event, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write(
      LogLevel.error,
      event,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _write(
    LogLevel level,
    String event, {
    required Map<String, Object?> fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final LogRecord record = LogRecord(
      timestamp: _clock().toUtc(),
      level: level,
      event: event,
      fields: _redact(fields),
      errorType: error?.runtimeType.toString(),
    );

    final void Function(LogRecord record)? sink = _sink;
    if (sink != null) {
      sink(record);
      return;
    }

    developer.log(
      record.toString(),
      name: 'chess_master',
      level: level.value,
      error: error,
      stackTrace: stackTrace,
      time: record.timestamp,
    );
  }

  Map<String, Object?> _redact(Map<String, Object?> fields) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> field in fields.entries)
        field.key: _sensitiveFieldNames.contains(field.key)
            ? '<redacted>'
            : field.value,
    };
  }
}

final class LogRecord {
  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.event,
    required this.fields,
    required this.errorType,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String event;
  final Map<String, Object?> fields;
  final String? errorType;

  @override
  String toString() {
    return <String, Object?>{
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'event': event,
      if (fields.isNotEmpty) 'fields': fields,
      if (errorType != null) 'errorType': errorType,
    }.toString();
  }
}
