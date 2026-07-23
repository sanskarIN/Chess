import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/app_error.dart';
import '../features/challenges/presentation/daily_challenges_screen.dart';
import '../features/chess/application/game_setup.dart';
import '../features/chess/presentation/game_screen.dart';
import '../features/chess/presentation/player_setup_screen.dart';
import '../features/friend_multiplayer/application/friend_game_launch.dart';
import '../features/friend_multiplayer/presentation/friend_lobby_screen.dart';
import '../features/guide/presentation/feature_catalog_screen.dart';
import '../features/guide/presentation/guide_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/mode_selection_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/practice/presentation/free_practice_board_screen.dart';
import '../features/practice/presentation/practice_hub_screen.dart';
import '../features/practice/presentation/practice_launch.dart';
import '../features/practice/presentation/puzzle_list_screen.dart';
import '../features/practice/presentation/puzzle_screen.dart';
import '../features/practice/presentation/tutorial_lesson_screen.dart';
import '../features/practice/presentation/tutorial_screen.dart';
import '../features/saved_games/domain/saved_game.dart';
import '../features/saved_games/presentation/review_screen.dart';
import '../features/saved_games/presentation/saved_games_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../l10n/app_localizations.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String modeSelection = '/play';
  static const String setup = '/play/:mode';
  static const String game = '/game';
  static const String friendGame = '/friend-game';
  static const String dailyChallenges = '/challenges';
  static const String practice = '/practice';
  static const String tutorial = '/tutorial';
  static const String tutorialLesson = '/tutorial/lesson';
  static const String puzzles = '/practice/puzzles';
  static const String puzzle = '/practice/puzzle';
  static const String practiceBoard = '/practice/board';
  static const String savedGames = '/saved-games';
  static const String savedGame = '/saved-game';
  static const String review = '/review';
  static const String guide = '/guide';
  static const String features = '/features';

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
          if (mode == GameMode.friend) {
            return const FriendLobbyScreen();
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
      GoRoute(
        path: AppRoutes.friendGame,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! FriendGameLaunch) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return GameScreen(
            setup: extra.setup,
            friendController: extra.controller,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dailyChallenges,
        builder: (BuildContext context, GoRouterState state) {
          return const DailyChallengesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.practice,
        builder: (BuildContext context, GoRouterState state) {
          return const PracticeHubScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (BuildContext context, GoRouterState state) {
          return const TutorialScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.tutorialLesson,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! TutorialLessonLaunch) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return TutorialLessonScreen(lesson: extra.lesson);
        },
      ),
      GoRoute(
        path: AppRoutes.puzzles,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          return PuzzleListScreen(
            type: extra is PuzzleListLaunch ? extra.type : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.puzzle,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! PuzzleLaunch) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return PuzzleScreen(puzzle: extra.puzzle);
        },
      ),
      GoRoute(
        path: AppRoutes.practiceBoard,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          return FreePracticeBoardScreen(
            initialPosition: extra is PracticeBoardLaunch
                ? extra.initialPosition
                : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.savedGames,
        builder: (BuildContext context, GoRouterState state) {
          return const SavedGamesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.savedGame,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! SavedGameLaunch) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return GameScreen(
            setup: extra.savedGame.setup,
            initialGame: extra.savedGame.game,
            savedGameId: extra.savedGame.id,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.review,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! ReviewLaunch) {
            return RouteErrorScreen(location: state.uri.toString());
          }
          return ReviewScreen(launch: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.guide,
        builder: (BuildContext context, GoRouterState state) {
          return const GuideScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.features,
        builder: (BuildContext context, GoRouterState state) {
          return const FeatureCatalogScreen();
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
