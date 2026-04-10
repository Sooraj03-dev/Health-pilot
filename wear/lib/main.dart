import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/watch_login_screen.dart';
import 'screens/watch_vitals_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Supabase credentials (hard-coded for the watch app – no .env on Wear OS)
// ──────────────────────────────────────────────────────────────────────────────
const _supabaseUrl = 'https://pchkoqbqwivknceokkax.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjaGtvcWJxd2l2a25jZW9ra2F4Iiwicm9sZSI6'
    'ImFub24iLCJpYXQiOjE3NzUzMDI5MjgsImV4cCI6MjA5MDg3ODkyOH0'
    '.XP0iCFvIp0x1z4egbutNeVESPq7I5ix8C_V4dLKnpEU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const HealthPilotWearApp());
}

class HealthPilotWearApp extends StatelessWidget {
  const HealthPilotWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Pilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF76FF03),
          surface: Color(0xFF121212),
        ),
      ),
      home: const _SplashRouter(),
    );
  }
}

/// Checks persisted session → routes to the correct screen.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    var patientId = prefs.getString('watch_patient_id');

    // Wipe malformed UUIDs from previous alpha builds so it doesn't infinite loop the 22P02 error.
    if (patientId != null && patientId.startsWith('dev-patient-')) {
      await prefs.remove('watch_patient_id');
      patientId = null;
    }

    if (!mounted) return;

    if (patientId != null && patientId.isNotEmpty) {
      // Persisted session found – go straight to vitals.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WatchVitalsScreen(patientId: patientId!),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WatchLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00E5FF),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
