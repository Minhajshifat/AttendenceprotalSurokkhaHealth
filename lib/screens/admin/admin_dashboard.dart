import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surokkha_attendance/screens/attendance_history_screen.dart';
import '../../widgets/admin/team_details_sheet.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../services/attendence_service.dart';
import '../../services/location_service.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/admin/area_overview_section.dart';
import '../../widgets/admin/team_section.dart';

class AdminDashboard extends StatefulWidget {
  final AppUser user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  final AttendanceService _attendanceService = AttendanceService();

  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  bool _isGettingLocation = false;

  Map<String, dynamic>? _myAttendance;

  Map<String, int> _areaSummary = {
    'total': 0,
    'checkedIn': 0,
    'missing': 0,
    'onTime': 0,
    'late': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  List<Map<String, dynamic>> _teams = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ==================================================
  // LOAD DASHBOARD
  // ==================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Future.wait([
        _loadMyAttendance(),
        _loadAreaSummary(),
        _loadTeams(),
      ]);
    } catch (e, stackTrace) {
      debugPrint('AREA MANAGER DASHBOARD ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load dashboard: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMyAttendance() async {
    _myAttendance = await _attendanceService.getTodayAttendance(
      widget.user.uid,
    );
  }

  Future<void> _loadAreaSummary() async {
    _areaSummary = await _adminService.getOrganizationSummary();
  }

  Future<void> _loadTeams() async {
    if (widget.user.role == 'superadmin') {
      _teams = await _adminService.getAllTeamSummaries();
      return;
    }

    if (widget.user.role == 'admin') {
      if (widget.user.teamIds.isEmpty) {
        _teams = [];
        return;
      }

      _teams = await _adminService.getAssignedTeamSummaries(
        widget.user.teamIds,
      );

      return;
    }

    _teams = [];
  } // ==================================================
  // OWN ATTENDANCE
  // ==================================================

  Future<void> _checkIn() async {
    if (_myAttendance != null || _isGettingLocation) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (!mounted) return;

      final confirmed = await _showCheckInDialog(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      if (!mounted || !confirmed) {
        return;
      }

      await _attendanceService.createAttendance(
        userId: widget.user.uid,
        employeeId: widget.user.employeeId,
        teamId: widget.user.teamId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      await _loadMyAttendance();

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance submitted successfully.')),
      );
    } catch (e, stackTrace) {
      debugPrint('AREA MANAGER CHECK-IN ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attendance error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<bool> _showCheckInDialog({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(
                'Confirm Attendance',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your current location has been detected.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latitude: ${latitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'Longitude: ${longitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'Accuracy: ${accuracy.toStringAsFixed(1)} m',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
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
        title: Text(
          'Area Manager Dashboard',
          style: GoogleFonts.poppins(
            color: const Color(0xFF155084),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Attendance History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceHistoryScreen(user: widget.user),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, color: Color(0xFF155084)),
          ),

          IconButton(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF155084)),
          ),

          const LogoutButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildGreeting(),

                  const SizedBox(height: 22),

                  _buildMyAttendance(),

                  const SizedBox(height: 28),

                  AreaOverviewSection(summary: _areaSummary),

                  const SizedBox(height: 28),

                  TeamsSection(teams: _teams, onViewTeam: _openTeamDetails),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==================================================
  // GREETING
  // ==================================================

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good day, ${widget.user.name}',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF172B4D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Area Manager • ${widget.user.employeeId}',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  // ==================================================
  // MY ATTENDANCE
  // ==================================================

  Widget _buildMyAttendance() {
    final timingStatus = _myAttendance?['timingStatus']?.toString();

    final attendanceStatus =
        _myAttendance?['attendanceStatus']?.toString() ??
        _myAttendance?['status']?.toString();

    final hasAttendance = _myAttendance != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_circle_outlined,
                color: Color(0xFF155084),
              ),
              const SizedBox(width: 8),
              Text(
                'My Attendance',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF172B4D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!hasAttendance)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : _checkIn,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.location_on_outlined),
                label: Text(
                  _isGettingLocation ? 'Getting Location...' : 'Check In',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155084),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        label: 'Check-in',
                        value: _formatTime(_myAttendance?['checkInTime']),
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        label: 'Timing',
                        value: _timingLabel(timingStatus),
                        valueColor: _timingColor(timingStatus),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Text(
                      'Attendance Status',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Spacer(),
                    _StatusChip(status: attendanceStatus ?? 'pending'),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceHistoryScreen(user: widget.user),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('View Attendance History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF155084),
                side: const BorderSide(color: Color(0xFF155084)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // AREA OVERVIEW
  // ==================================================

  // ==================================================
  // TEAMS
  // ==================================================

  // ==================================================
  // TEAM DETAILS
  // ==================================================
  void _openTeamDetails(String teamId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return TeamDetailsSheet(teamId: teamId, areaManagerId: widget.user.uid);
      },
    );
  }

  // ==================================================
  // HELPERS
  // ==================================================

  String _formatTime(dynamic value) {
    if (value == null) {
      return '—';
    }

    try {
      final dateTime = value.toDate();

      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;

      final minute = dateTime.minute.toString().padLeft(2, '0');

      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return 'Processing...';
    }
  }

  String _timingLabel(String? status) {
    switch (status) {
      case 'on_time':
        return 'On Time';
      case 'late':
        return 'Late';
      default:
        return '—';
    }
  }

  Color _timingColor(String? status) {
    switch (status) {
      case 'on_time':
        return const Color(0xFF43C047);
      case 'late':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }
}

// ==================================================
// SUMMARY CARD
// ==================================================

// ==================================================
// SMALL STAT
// ==================================================

// ==================================================
// INFO ITEM
// ==================================================
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF172B4D),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();

    final isApproved = normalizedStatus == 'approved';
    final isRejected = normalizedStatus == 'rejected';

    final color = isApproved
        ? const Color(0xFF43C047)
        : isRejected
        ? Colors.red
        : Colors.orange;

    final label = isApproved
        ? 'Approved'
        : isRejected
        ? 'Rejected'
        : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
