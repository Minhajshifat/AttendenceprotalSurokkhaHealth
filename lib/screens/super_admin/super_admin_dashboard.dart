import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surokkha_attendance/screens/super_admin/attendance_history_screen_super.dart';
import 'package:surokkha_attendance/screens/super_admin/employee_management_screen.dart';

import '../../models/app_user.dart';
import '../../services/super_admin_service.dart';
import '../../widgets/logout_button.dart';
import 'attendance_approval_screen.dart';
import 'lib/screens/super_admin/area_management_screen.dart';
import 'team_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;

  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final SuperAdminService _service = SuperAdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _usersSubscription;
  StreamSubscription? _teamsSubscription;
  StreamSubscription? _attendanceSubscription;

  bool _isLoading = true;
  String? _error;

  int _agents = 0;
  int _teamLeads = 0;
  int _areaManagers = 0;
  int _teams = 0;
  int _pendingApprovals = 0;

  @override
  void initState() {
    super.initState();

    _loadDashboard();
    _listenToDashboardChanges();
  }

  // ==================================================
  // LOAD DASHBOARD
  // ==================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final stats = await _service.getDashboardStats();

      if (!mounted) return;

      setState(() {
        _agents = stats['agents'] ?? 0;
        _teamLeads = stats['teamLeads'] ?? 0;
        _areaManagers = stats['areaManagers'] ?? 0;
        _teams = stats['teams'] ?? 0;
        _pendingApprovals = stats['pendingApprovals'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to load dashboard data.';
      });
    }
  }

  // ==================================================
  // REAL-TIME DASHBOARD LISTENERS
  // ==================================================

  void _listenToDashboardChanges() {
    _usersSubscription = _firestore
        .collection('users')
        .snapshots()
        .listen(
          (_) {
            _refreshDashboardStats();
          },
          onError: (error) {
            debugPrint('USERS STREAM ERROR: $error');
          },
        );

    _teamsSubscription = _firestore
        .collection('teams')
        .snapshots()
        .listen(
          (_) {
            _refreshDashboardStats();
          },
          onError: (error) {
            debugPrint('TEAMS STREAM ERROR: $error');
          },
        );

    _attendanceSubscription = _firestore
        .collection('attendance')
        .snapshots()
        .listen(
          (_) {
            _refreshDashboardStats();
          },
          onError: (error) {
            debugPrint('ATTENDANCE STREAM ERROR: $error');
          },
        );
  }

  Future<void> _refreshDashboardStats() async {
    try {
      final stats = await _service.getDashboardStats();

      if (!mounted) return;

      setState(() {
        _agents = stats['agents'] ?? 0;
        _teamLeads = stats['teamLeads'] ?? 0;
        _areaManagers = stats['areaManagers'] ?? 0;
        _teams = stats['teams'] ?? 0;
        _pendingApprovals = stats['pendingApprovals'] ?? 0;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('REAL-TIME DASHBOARD REFRESH ERROR: $e');
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _teamsSubscription?.cancel();
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Super Admin',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF172B4D),
              ),
            ),
            Text(
              widget.user.name,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF155084)),
          ),
          const LogoutButton(),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF155084)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildWelcome(),
          const SizedBox(height: 24),
          _buildSectionTitle('Overview'),
          const SizedBox(height: 12),
          _buildOverview(),
          const SizedBox(height: 28),
          _buildSectionTitle('Management'),
          const SizedBox(height: 12),
          _buildManagement(),
          const SizedBox(height: 28),
          _buildSectionTitle('Attendance'),
          const SizedBox(height: 12),
          _buildAttendanceCard(),
        ],
      ),
    );
  }

  // ==================================================
  // WELCOME
  // ==================================================

  Widget _buildWelcome() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF155084), Color(0xFF1B6A9E)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'System Administrator',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF172B4D),
      ),
    );
  }

  // ==================================================
  // OVERVIEW
  // ==================================================

  Widget _buildOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1300) {
          columns = 5;
        } else if (width >= 900) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth = (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard('Agents', '$_agents', Icons.person_outline),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard('Teams', '$_teams', Icons.groups_outlined),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Team Leads',
                '$_teamLeads',
                Icons.supervisor_account_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Area Managers',
                '$_areaManagers',
                Icons.manage_accounts_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                'Pending Approvals',
                '$_pendingApprovals',
                Icons.pending_actions_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF155084)),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172B4D),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // MANAGEMENT
  // ==================================================

  Widget _buildManagement() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 1000) {
          return Row(
            children: [
              Expanded(
                child: _managementCard(
                  title: 'Employee Management',
                  subtitle: 'Add and manage employees',
                  icon: Icons.people_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmployeeManagementScreen(),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _managementCard(
                  title: 'Team Management',
                  subtitle: 'Create teams and assign members',
                  icon: Icons.groups_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeamManagementScreen(),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _managementCard(
                  title: 'Area Management',
                  subtitle: 'Manage areas and managers',
                  icon: Icons.location_city_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AreaManagementScreen(user: widget.user),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _managementCard(
                  title: 'Attendance History',
                  subtitle: 'View daily attendance records',
                  icon: Icons.history_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceHistoryScreenSuper(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _managementCard(
              title: 'Employee Management',
              subtitle: 'Add and manage employees',
              icon: Icons.people_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployeeManagementScreen(),
                  ),
                ).then((_) => _loadDashboard());
              },
            ),
            const SizedBox(height: 12),
            _managementCard(
              title: 'Team Management',
              subtitle: 'Create teams and assign members',
              icon: Icons.groups_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeamManagementScreen(),
                  ),
                ).then((_) => _loadDashboard());
              },
            ),
            const SizedBox(height: 12),
            _managementCard(
              title: 'Area Management',
              subtitle: 'Manage areas and managers',
              icon: Icons.location_city_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AreaManagementScreen(user: widget.user),
                  ),
                ).then((_) => _loadDashboard());
              },
            ),
            const SizedBox(height: 12),
            _managementCard(
              title: 'Attendance History',
              subtitle: 'View daily attendance records',
              icon: Icons.history_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryScreenSuper(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _managementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 105,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF155084), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // ATTENDANCE
  // ==================================================

  Widget _buildAttendanceCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceApprovalScreen(user: widget.user),
          ),
        ).then((_) => _loadDashboard());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Approval',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and approve attendance records',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_pendingApprovals Pending',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
