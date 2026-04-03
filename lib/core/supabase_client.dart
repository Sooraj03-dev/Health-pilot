import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

/// Initialises the Supabase client. Call once in main() before runApp().
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
}

/// Convenience getter for the global Supabase client.
SupabaseClient get supabase => Supabase.instance.client;
