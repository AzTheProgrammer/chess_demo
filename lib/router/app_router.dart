import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/view/home_screen.dart';
import '../features/play/view/play_screen.dart';
import '../features/analysis/view/analysis_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/train/view/train_hub_screen.dart';
import '../features/openings/view/openings_screen.dart';
import '../features/tactics/view/tactics_screen.dart';
import '../features/square_trainer/view/square_trainer_screen.dart';
import '../core/widgets/app_shell.dart';
import '../infrastructure/persistence/game_repository.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/play',
                builder: (context, state) => const PlayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (context, state) => const TrainHubScreen(),
                routes: [
                  GoRoute(
                    path: 'openings',
                    builder: (context, state) => const OpeningsScreen(),
                  ),
                  GoRoute(
                    path: 'tactics',
                    builder: (context, state) => const TacticsScreen(),
                  ),
                  GoRoute(
                    path: 'squares',
                    builder: (context, state) => const SquareTrainerScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analyze',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is SavedGame) {
                    return AnalysisScreen(initialSavedGame: extra);
                  }
                  if (extra is String) {
                    return AnalysisScreen(initialPgn: extra);
                  }
                  return const AnalysisScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
