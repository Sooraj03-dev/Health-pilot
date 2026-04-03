import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/stat_data.dart';
import '../../router.dart';
import '../../widgets/dashboard_shell.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = authState.value!;
    return DashboardShell(
      title: 'Doctor Dashboard',
      userName: user.name,
      roleLabel: user.roleLabel,
      accentColor: AppColors.doctorColor,
      gradient: AppColors.doctorGradient,
      icon: Icons.medical_services_rounded,
      statCards: const [
        StatData('Patients', '24', Icons.people_rounded),
        StatData('Appointments', '8', Icons.calendar_month_rounded),
        StatData('Messages', '12', Icons.chat_rounded),
        StatData('Reports', '5', Icons.description_rounded),
      ],
    );
  }
}
