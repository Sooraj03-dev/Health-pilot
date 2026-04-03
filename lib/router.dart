import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/user_model.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/pending_verification.dart';
import 'screens/dashboards/patient_dashboard.dart';
import 'screens/dashboards/doctor_dashboard.dart';
import 'screens/dashboards/admin_dashboard.dart';

// ---------------------------------------------------------------------------
// Global auth state — drives GoRouter's redirect guard via refreshListenable.
// Setting this to null = logged out; setting to an AppUser = logged in.
// ---------------------------------------------------------------------------
final ValueNotifier<AppUser?> authState = ValueNotifier<AppUser?>(null);

// ---------------------------------------------------------------------------
// GoRouter configuration
// ---------------------------------------------------------------------------
final GoRouter router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authState,
  redirect: _guardRedirect,
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/patient',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PatientDashboard(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/doctor',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DoctorDashboard(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/pending',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PendingVerificationScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AdminDashboard(),
        transitionsBuilder: _slideTransition,
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Redirect guard — enforces role-based access on every navigation event.
// ---------------------------------------------------------------------------
String? _guardRedirect(BuildContext context, GoRouterState state) {
  final user = authState.value;
  final loggedIn = user != null;
  final currentPath = state.matchedLocation;
  final onLoginPage = currentPath == '/login';

  // 1. Not logged in → must be on /login
  if (!loggedIn) {
    return onLoginPage ? null : '/login';
  }

  // 2. Logged in but still on /login → send to correct dashboard
  if (onLoginPage) {
    return _homePathForUser(user);
  }

  // 3. Logged in, trying to reach a page outside their allowed path → redirect
  final allowedPath = _homePathForUser(user);
  if (currentPath != allowedPath) {
    return allowedPath;
  }

  // 4. Everything matches — allow navigation
  return null;
}

/// Maps a user to their allowed route based on role + verification status.
String _homePathForUser(AppUser user) {
  switch (user.role) {
    case 'patient':
      return '/patient';
    case 'doctor':
      return user.isVerified ? '/doctor' : '/pending';
    case 'admin':
      return '/admin';
    default:
      return '/login';
  }
}

// ---------------------------------------------------------------------------
// Shared page transition — slide up with fade
// ---------------------------------------------------------------------------
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final offsetTween = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  return SlideTransition(
    position: animation.drive(offsetTween),
    child: FadeTransition(opacity: animation, child: child),
  );
}
