/// Represents an authenticated user in the Health Pilot system.
///
/// Each user has a [role] that determines which dashboard they can access,
/// and an [isVerified] flag used for doctor verification gating.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // "patient" | "doctor" | "admin"
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isVerified = false,
  });

  /// Returns a human-readable label for the user's role.
  String get roleLabel {
    switch (role) {
      case 'patient':
        return 'Patient';
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Admin';
      default:
        return 'Unknown';
    }
  }
}
