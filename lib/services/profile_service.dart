import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Service that manages user profiles in the Supabase `profiles` table.
class ProfileService {
  final SupabaseClient _client;

  ProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Inserts a new profile row for the given [userId] and [role].
  ///
  /// Returns the created [UserModel].
  Future<UserModel> createProfile(String userId, String role) async {
    final response = await _client
        .from('profiles')
        .insert({
          'user_id': userId,
          'role': role,
        })
        .select()
        .single();

    return UserModel.fromMap(response);
  }

  /// Fetches the profile for the given [userId].
  ///
  /// Returns `null` if no profile exists.
  Future<UserModel?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromMap(response);
  }
}
