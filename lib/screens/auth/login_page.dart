import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _login(AppUser user) {
    authState.value = user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background circles
          ..._buildBackgroundOrbs(),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SlideTransition(
                  position: _slideUp,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo / Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.health_and_safety_rounded,
                              color: Colors.white, size: 42),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Health Pilot',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose a role to continue',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 44),

                        // Role cards
                        _RoleCard(
                          icon: Icons.person_rounded,
                          label: 'Patient',
                          subtitle: 'Track vitals & chat with doctors',
                          gradient: AppColors.patientGradient,
                          accentColor: AppColors.patientColor,
                          onTap: () => _login(const AppUser(
                            id: '1',
                            name: 'Alice Johnson',
                            email: 'alice@health.io',
                            role: 'patient',
                          )),
                        ),
                        const SizedBox(height: 14),
                        _RoleCard(
                          icon: Icons.medical_services_rounded,
                          label: 'Doctor (verified)',
                          subtitle: 'Manage patients & consultations',
                          gradient: AppColors.doctorGradient,
                          accentColor: AppColors.doctorColor,
                          onTap: () => _login(const AppUser(
                            id: '2',
                            name: 'Dr. Bob Smith',
                            email: 'bob@health.io',
                            role: 'doctor',
                            isVerified: true,
                          )),
                        ),
                        const SizedBox(height: 14),
                        _RoleCard(
                          icon: Icons.hourglass_top_rounded,
                          label: 'Doctor (pending)',
                          subtitle: 'Awaiting admin verification',
                          gradient: LinearGradient(
                            colors: [
                              AppColors.pendingColor,
                              AppColors.pendingColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          accentColor: AppColors.pendingColor,
                          onTap: () => _login(const AppUser(
                            id: '3',
                            name: 'Dr. Charlie Lee',
                            email: 'charlie@health.io',
                            role: 'doctor',
                            isVerified: false,
                          )),
                        ),
                        const SizedBox(height: 14),
                        _RoleCard(
                          icon: Icons.admin_panel_settings_rounded,
                          label: 'Admin',
                          subtitle: 'Full platform management',
                          gradient: AppColors.adminGradient,
                          accentColor: AppColors.adminColor,
                          onTap: () => _login(const AppUser(
                            id: '4',
                            name: 'Dave Admin',
                            email: 'dave@health.io',
                            role: 'admin',
                          )),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundOrbs() {
    return [
      Positioned(
        top: -60,
        right: -40,
        child: _Orb(size: 220, color: AppColors.primary.withOpacity(0.06)),
      ),
      Positioned(
        bottom: -80,
        left: -50,
        child: _Orb(size: 260, color: AppColors.accent.withOpacity(0.06)),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Role selection card
// ---------------------------------------------------------------------------
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_hovering ? 1.02 : 1.0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.bgCardHover : AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovering
                  ? widget.accentColor.withOpacity(0.4)
                  : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? widget.accentColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _hovering ? 24 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gradient icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative blurred orb
// ---------------------------------------------------------------------------
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
