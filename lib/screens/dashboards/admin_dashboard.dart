import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/stat_data.dart';
import '../../router.dart';
import '../../widgets/dashboard_shell.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authState.value!;
    return DashboardShell(
      title: 'Admin Dashboard',
      userName: user.name,
      roleLabel: user.roleLabel,
      accentColor: AppColors.adminColor,
      gradient: AppColors.adminGradient,
      icon: Icons.admin_panel_settings_rounded,
      statCards: const [
        StatData('Users', '1 287', Icons.people_alt_rounded),
        StatData('Doctors', '84', Icons.medical_services_rounded),
        StatData('Pending', '6', Icons.hourglass_top_rounded),
        StatData('Alerts', '3', Icons.warning_amber_rounded),
      ],
    );
  }
}
