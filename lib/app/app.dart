import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/app_error.dart';
import '../l10n/app_localizations.dart';
import 'app_config.dart';
import 'app_router.dart';
import 'app_theme.dart';

final class ChessMasterApp extends ConsumerStatefulWidget {
  const ChessMasterApp({super.key, this.startupError});

  final AppError? startupError;

  @override
  ConsumerState<ChessMasterApp> createState() => _ChessMasterAppState();
}

final class _ChessMasterAppState extends ConsumerState<ChessMasterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(startupError: widget.startupError);
  }

  @override
  Widget build(BuildContext context) {
    final AppConfig config = ref.watch(appConfigProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => config.displayName,
      routerConfig: _router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
