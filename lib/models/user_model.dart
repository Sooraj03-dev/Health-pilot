class UserModel {
  final String userId;
  final String role;
  final bool isVerified;
  final String? fullName;

  UserModel({
    required this.userId,
    required this.role,
    this.isVerified = false,
    this.fullName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'patient',
      isVerified: json['is_verified'] as bool? ?? false,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role,
      'is_verified': isVerified,
      'full_name': fullName,
    };
  }
}
