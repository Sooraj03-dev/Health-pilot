import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/stat_data.dart';
import '../../router.dart';
import '../../widgets/dashboard_shell.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authState.value!;
    return DashboardShell(
      title: 'Patient Dashboard',
      userName: user.name,
      roleLabel: user.roleLabel,
      accentColor: AppColors.patientColor,
      gradient: AppColors.patientGradient,
      icon: Icons.favorite_rounded,
      statCards: const [
        StatData('Heart Rate', '72 bpm', Icons.monitor_heart_rounded),
        StatData('Steps', '8 432', Icons.directions_walk_rounded),
        StatData('SpO\u2082', '98 %', Icons.air_rounded),
        StatData('Sleep', '7h 14m', Icons.bedtime_rounded),
      ],
    );
  }
}
