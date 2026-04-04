import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/user_model.dart';

class ProfileService {
  Future<UserModel?> fetchProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<void> upsertProfile(UserModel user) async {
    await supabase.from('profiles').upsert(user.toJson());
  }
}
