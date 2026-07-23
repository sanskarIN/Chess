import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/app_error.dart';
import '../features/chess/application/game_setup.dart';
import '../features/chess/presentation/game_screen.dart';
import '../features/chess/presentation/player_setup_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/mode_selection_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../l10n/app_localizations.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String modeSelection = '/play';
  static const String setup = '/play/:mode';
  static const String game = '/game';

  static String setupPath(GameMode mode) => '/play/${mode.name}';
}

GoRouter createAppRouter({required AppError? startupError}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) {
          return SplashScreen(startupError: startupError);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.modeSelection,
        builder: (BuildContext context, GoRouterState state) {
          return const ModeSelectionScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (BuildContext context, GoRouterState state) {
          final GameMode? mode = _parseGameMode(state.pathParameters['mode']);
          if (mode == null) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return PlayerSetupScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! GameSetup) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return GameScreen(setup: extra);
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return RouteErrorScreen(location: state.uri.toString());
    },
  );
}

GameMode? _parseGameMode(String? value) {
  for (final GameMode mode in GameMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }
  return null;
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
