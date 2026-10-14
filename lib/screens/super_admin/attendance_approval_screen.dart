import 'package:flutter/material.dart';
import 'lib/screens/super_admin/office_employee_attendance_screen.dart';

import '../../models/app_user.dart';
import 'area_manager_attendance_screen.dart';
import 'team_approval_screen.dart';

class AttendanceApprovalScreen extends StatelessWidget {
  final AppUser user;

  const AttendanceApprovalScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance Approval',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildOfficeEmployeeCard(context),

          const SizedBox(height: 16),

          _buildAreaManagerCard(context),

          const SizedBox(height: 16),

          _buildTeamCard(context),
        ],
      ),
    );
  }

  Widget _buildOfficeEmployeeCard(BuildContext context) {
    return _ApprovalCard(
      icon: Icons.business_outlined,
      title: 'Office Employee Attendance',
      subtitle: 'Review office employee attendance by designation',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfficeEmployeeAttendanceScreen(user: user),
          ),
        );
      },
    );
  }

  Widget _buildAreaManagerCard(BuildContext context) {
    return _ApprovalCard(
      icon: Icons.manage_accounts_outlined,
      title: 'Area Manager Attendance',
      subtitle: 'Review and approve area manager attendance',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AreaManagerAttendanceScreen(user: user),
          ),
        );
      },
    );
  }

  Widget _buildTeamCard(BuildContext context) {
    return _ApprovalCard(
      icon: Icons.groups_outlined,
      title: 'Team Attendance',
      subtitle: 'Review attendance by team',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeamApprovalScreen(user: user)),
        );
      },
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ApprovalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8EF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFF155084), size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A8491),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7A8491),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
