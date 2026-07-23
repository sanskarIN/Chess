import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'core/database/app_database.dart';
import 'core/database/database_providers.dart';
import 'core/database/sqflite_app_database.dart';
import 'core/errors/app_error.dart';
import 'core/logging/app_logger.dart';

Future<void> bootstrap() async {
  final AppLogger logger = AppLogger();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        logger.error(
          'flutter.framework_error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      final AppConfig config = AppConfig.fromEnvironment();
      AppDatabase? database;
      AppError? startupError;

      try {
        database = SqfliteAppDatabase(logger: logger);
        await database.open();
      } on Object catch (error, stackTrace) {
        startupError = StorageError(
          code: 'database_initialization_failed',
          messageKey: 'errorDatabaseUnavailable',
          technicalDetails: error.toString(),
        );
        logger.error(
          'database.initialization_failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      runApp(
        ProviderScope(
          overrides: <Override>[
            appConfigProvider.overrideWithValue(config),
            appDatabaseProvider.overrideWithValue(database),
            appLoggerProvider.overrideWithValue(logger),
          ],
          child: ChessMasterApp(startupError: startupError),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      logger.error(
        'dart.uncaught_zone_error',
        error: error,
        stackTrace: stackTrace,
      );
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
    },
  );
}
