import 'package:go_router/go_router.dart';
import 'screens/pending_verification_screen.dart';
import 'widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppShell(),
    ),
    GoRoute(
      path: '/pending-verification',
      builder: (context, state) => const PendingVerificationScreen(),
    ),
  ],
);
