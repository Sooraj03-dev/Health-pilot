/// Represents a user profile synced with the Supabase `profiles` table.
class UserModel {
  final String userId;
  final String role; // 'patient' | 'doctor' | 'caregiver'
  final bool isVerified;

  const UserModel({
    required this.userId,
    required this.role,
    this.isVerified = false,
  });

  /// Creates a [UserModel] from a Supabase row map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String,
      role: map['role'] as String,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }

  /// Converts this model to a map for Supabase inserts/updates.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'role': role,
      'is_verified': isVerified,
    };
  }

  @override
  String toString() =>
      'UserModel(userId: $userId, role: $role, isVerified: $isVerified)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          role == other.role &&
          isVerified == other.isVerified;

  @override
  int get hashCode => Object.hash(userId, role, isVerified);
}
