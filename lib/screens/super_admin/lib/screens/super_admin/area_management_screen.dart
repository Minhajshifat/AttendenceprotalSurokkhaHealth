import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surokkha_attendance/models/app_user.dart';
import 'package:surokkha_attendance/screens/super_admin/field_location_screen.dart';
import 'package:surokkha_attendance/screens/super_admin/lib/screens/super_admin/office_location_screen.dart';

import 'package:surokkha_attendance/services/team_service.dart';

class AreaManagementScreen extends StatefulWidget {
  final AppUser user;

  const AreaManagementScreen({super.key, required this.user});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        title: Text(
          'Area Management',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildSectionTitle('Location Management'),

          const SizedBox(height: 12),

          _buildManagementCard(
            icon: Icons.business_outlined,
            title: 'Office Location',
            subtitle: 'Manage the fixed office attendance location',
            onTap: _openOfficeLocation,
          ),

          const SizedBox(height: 12),

          _buildManagementCard(
            icon: Icons.location_on_outlined,
            title: 'Field Location',
            subtitle: 'Assign daily locations for Agents and Team Leads',
            onTap: _openFieldLocation,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Area Manager Management'),

          const SizedBox(height: 12),

          _buildAreaManagersCard(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==================================================
  // HEADER
  // ==================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF155084), Color(0xFF1B6A9E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_city_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Area Management',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Manage office and field locations',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // SECTION TITLE
  // ==================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF172B4D),
      ),
    );
  }

  // ==================================================
  // MANAGEMENT CARD
  // ==================================================

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8EF)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FA),
                borderRadius: BorderRadius.circular(12),
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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF7A8491),
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

  // ==================================================
  // AREA MANAGERS
  // ==================================================

  Widget _buildAreaManagersCard() {
    return StreamBuilder(
      stream: _teamService.getAreaManagers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _simpleCard(
            icon: Icons.manage_accounts_outlined,
            title: 'Area Managers',
            subtitle: 'Unable to load area managers',
            trailing: const Icon(Icons.error_outline, color: Color(0xFFE53935)),
          );
        }

        if (!snapshot.hasData) {
          return _simpleCard(
            icon: Icons.manage_accounts_outlined,
            title: 'Area Managers',
            subtitle: 'Loading area managers...',
            trailing: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF155084),
              ),
            ),
          );
        }

        final managers = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_outlined,
                      color: Color(0xFF155084),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Area Managers',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF172B4D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${managers.length} Area Manager${managers.length == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF7A8491),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (managers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFECEFF3)),
                const SizedBox(height: 8),

                ...managers.map((document) {
                  final data = document.data();

                  final name = data['name']?.toString() ?? '-';

                  final employeeId = data['employeeId']?.toString() ?? '-';

                  final teamIds = data['teamIds'] is List
                      ? List<dynamic>.from(data['teamIds'])
                      : <dynamic>[];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFFEAF3FA),
                          child: Text(
                            _initials(name),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF155084),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF172B4D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                employeeId,
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: const Color(0xFF7A8491),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FA),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${teamIds.length} team${teamIds.length == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF155084),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const SizedBox(height: 14),
                Text(
                  'No Area Managers found',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF7A8491),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==================================================
  // SIMPLE CARD
  // ==================================================

  Widget _simpleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FA),
              borderRadius: BorderRadius.circular(12),
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
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF7A8491),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // ==================================================
  // OFFICE LOCATION
  // ==================================================

  void _openOfficeLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfficeLocationScreen(user: widget.user),
      ),
    );
  }

  // ==================================================
  // FIELD LOCATION
  // ==================================================

  void _openFieldLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FieldLocationScreen(user: widget.user)),
    );
  }

  // ==================================================
  // INITIALS
  // ==================================================

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
