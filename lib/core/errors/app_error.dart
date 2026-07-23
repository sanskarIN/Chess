sealed class AppError {
  const AppError({
    required this.code,
    required this.messageKey,
    this.technicalDetails,
  });

  final String code;
  final String messageKey;
  final String? technicalDetails;

  @override
  String toString() => '$runtimeType(code: $code, messageKey: $messageKey)';
}

final class ValidationError extends AppError {
  const ValidationError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
    this.field,
  });

  final String? field;
}

final class StorageError extends AppError {
  const StorageError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
  });
}

final class NetworkError extends AppError {
  const NetworkError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
    this.isRetryable = false,
  });

  final bool isRetryable;
}

final class EngineError extends AppError {
  const EngineError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
    this.isRetryable = false,
  });

  final bool isRetryable;
}

final class GameStateError extends AppError {
  const GameStateError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
  });
}

final class ImportError extends AppError {
  const ImportError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
  });
}

final class LocalizationError extends AppError {
  const LocalizationError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
    this.locale,
  });

  final String? locale;
}

final class PermissionError extends AppError {
  const PermissionError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
  });
}

final class UnknownError extends AppError {
  const UnknownError({
    required super.code,
    required super.messageKey,
    super.technicalDetails,
  });
}
