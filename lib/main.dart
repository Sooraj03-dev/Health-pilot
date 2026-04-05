import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/core/theme.dart';
import 'package:health_pilot/router.dart';
import 'package:health_pilot/services/notification_service.dart';
import 'package:health_pilot/services/watch_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: '.env');

  // Initialise Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final container = ProviderContainer();
  
  // Initialize notifications and request permissions on app launch
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init();
  await notificationService.requestPermissions();

  // Start background periodic syncing of health vitals
  WatchService().startSyncing();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const HealthPilotApp(),
  ));
}

/// Root widget for Health Pilot.
class HealthPilotApp extends ConsumerWidget {
  const HealthPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Keep the SOS subscription active 
    ref.watch(sosSubscriptionProvider);

    return MaterialApp.router(
      title: 'Health Pilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
