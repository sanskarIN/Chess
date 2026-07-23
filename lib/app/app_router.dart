import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/app_error.dart';
import '../features/foundation/presentation/foundation_screen.dart';
import '../l10n/app_localizations.dart';

abstract final class AppRoutes {
  static const String foundation = '/';
}

GoRouter createAppRouter({required AppError? startupError}) {
  return GoRouter(
    initialLocation: AppRoutes.foundation,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.foundation,
        builder: (BuildContext context, GoRouterState state) {
          return FoundationScreen(startupError: startupError);
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return RouteErrorScreen(location: state.uri.toString());
    },
  );
}

final class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.routeNotFoundTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.routeNotFoundDescription(location),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
