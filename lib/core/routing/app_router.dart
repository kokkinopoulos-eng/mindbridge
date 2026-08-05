import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/exercises/presentation/exercises_screen.dart';
import '../../features/assessment/presentation/assessment_screen.dart';
import '../../features/settings/presentation/api_settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

part 'app_router.g.dart';

// ── Route paths ────────────────────────────────────────────────────────────
abstract final class AppRoutes {
  static const splash      = '/';
  static const login       = '/login';
  static const register    = '/register';
  static const onboarding  = '/onboarding';
  static const home        = '/home';
  static const chat        = '/home/chat';
  static const exercises   = '/home/exercises';
  static const progress    = '/home/progress';
  static const assessment   = '/assessment/:type';
  static const assessResult = '/assessment/:type/result';
  static const apiSettings  = '/settings/api';

  static String assessmentPath(String type) => '/assessment/$type';
  static String assessResultPath(String type) => '/assessment/$type/result';
}

// ── Router provider ────────────────────────────────────────────────────────
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn  = authState.valueOrNull?.isAuthenticated ?? false;
      final isOnboarded = authState.valueOrNull?.isOnboarded ?? false;
      final loc         = state.matchedLocation;
      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;
      final isSplash    = loc == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute && !isSplash) return AppRoutes.login;
      if (!isLoggedIn && isSplash) return null; // wait on splash while loading
      if (isLoggedIn && isSplash) return AppRoutes.home;
      if (isLoggedIn && !isOnboarded && loc != AppRoutes.onboarding) return AppRoutes.onboarding;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _fadeTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, state) => _fadeTransition(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fadeTransition(state, const OnboardingScreen()),
      ),
      // ── Shell route (bottom nav) ────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.chat,
              builder: (_, __) => const ChatScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.exercises,
              builder: (_, __) => const ExercisesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (_, __) => const AssessmentScreen(),
            ),
          ]),
        ],
      ),
      // ── Standalone routes ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.apiSettings,
        pageBuilder: (_, state) =>
            _fadeTransition(state, const ApiSettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.assessment,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return AssessmentScreen(assessmentType: type);
        },
      ),
      GoRoute(
        path: AppRoutes.assessResult,
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return AssessmentResultScreen(assessmentType: type);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

// ── Transitions ────────────────────────────────────────────────────────────
CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

// ── Minimal splash ─────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
