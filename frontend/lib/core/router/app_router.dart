import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/aim_test/aim_test_page.dart';
import '../../features/auth/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/oauth_callback_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/leaderboard/leaderboard_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reaction_test/reaction_test_page.dart';
import '../../features/settings/settings_page.dart';
import '../constants/app_routes.dart';
import '../theme/app_motion.dart';
import 'split_curtain_route_transition.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.authCallback;
      final protectedRoute = location == AppRoutes.profile;

      if (authState.status == AuthStatus.loading) {
        return null;
      }

      if (protectedRoute && !authState.isAuthenticated) {
        return AppRoutes.login;
      }

      if (authRoute && authState.isAuthenticated) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _page(state, const HomePage()),
      ),
      GoRoute(
        path: AppRoutes.reactionTest,
        pageBuilder: (context, state) => _page(state, const ReactionTestPage()),
      ),
      GoRoute(
        path: AppRoutes.aimTest,
        pageBuilder: (context, state) => _page(state, const AimTestPage()),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        pageBuilder: (context, state) => _page(state, const LeaderboardPage()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _page(state, const ProfilePage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _page(state, const SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _page(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _page(state, const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.authCallback,
        pageBuilder: (context, state) => _page(
          state,
          OAuthCallbackPage(code: state.uri.queryParameters['code']),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppDurations.routeCurtain,
    reverseTransitionDuration: AppDurations.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SplitCurtainRouteTransition(animation: animation, child: child);
    },
  );
}
