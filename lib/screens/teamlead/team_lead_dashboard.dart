import 'package:flutter/material.dart';
import 'package:surokkha_attendance/screens/attendance_history_screen.dart';
import 'package:surokkha_attendance/widgets/logout_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../services/attendence_service.dart';
import '../../services/location_service.dart';

import '../../widgets/attendence/attendance_status_card.dart';
import '../../widgets/attendence/attendance_timing_card.dart';
import '../../widgets/attendence/check_in_confirmation_dialog.dart';
import '../../widgets/attendence/team_member_attendance_card.dart';

import '../../widgets/dashboad/dashboard_greeting.dart';
import '../../widgets/dashboad/attendance_stats.dart';

class TeamLeadDashboard extends StatefulWidget {
  final AppUser user;

  const TeamLeadDashboard({super.key, required this.user});

  @override
  State<TeamLeadDashboard> createState() => _TeamLeadDashboardState();
}

class _TeamLeadDashboardState extends State<TeamLeadDashboard> {
  final AttendanceService _attendanceService = AttendanceService();

  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  bool _isGettingLocation = false;

  Map<String, dynamic>? _myAttendance;

  List<Map<String, dynamic>> _members = [];

  String? _updatingEmployeeId;

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
      await Future.wait([_loadMyAttendance(), _loadTeamMembers()]);
    } catch (e, stackTrace) {
      debugPrint('TEAM LEAD DASHBOARD ERROR: $e');

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

  Future<void> _loadTeamMembers() async {
    _members = await _attendanceService.getTeamMembersAttendance(
      teamId: widget.user.teamId,
      currentUserId: widget.user.uid,
    );
  }

  // ==================================================
  // STATISTICS
  // ==================================================

  int get _totalMembers => _members.length;

  int get _checkedIn =>
      _members.where((member) => member['attendance'] != null).length;

  int get _missing => _totalMembers - _checkedIn;

  int get _onTime => _members
      .where((member) => _timingStatus(member['attendance']) == 'on_time')
      .length;

  int get _late => _members
      .where((member) => _timingStatus(member['attendance']) == 'late')
      .length;

  int get _pending => _members
      .where((member) => _approvalStatus(member['attendance']) == 'pending')
      .length;

  int get _approved => _members
      .where((member) => _approvalStatus(member['attendance']) == 'approved')
      .length;

  int get _rejected => _members
      .where((member) => _approvalStatus(member['attendance']) == 'rejected')
      .length;

  String? _timingStatus(dynamic attendance) {
    if (attendance is! Map<String, dynamic>) {
      return null;
    }

    return attendance['timingStatus']?.toString();
  }

  String? _approvalStatus(dynamic attendance) {
    if (attendance is! Map<String, dynamic>) {
      return null;
    }

    return attendance['attendanceStatus']?.toString() ??
        attendance['status']?.toString();
  }

  bool _teamLeadReviewed(dynamic attendance) {
    if (attendance is! Map<String, dynamic>) {
      return false;
    }

    return attendance['teamLeadReviewed'] == true;
  }

  // ==================================================
  // TEAM LEAD REVIEW
  // ==================================================

  Future<void> _reviewAttendance(String uid) async {
    if (_updatingEmployeeId != null) {
      return;
    }

    setState(() {
      _updatingEmployeeId = uid;
    });

    try {
      final dateKey = _attendanceService.getTodayDateKey();

      final attendanceId = '${uid}_$dateKey';

      await _attendanceService.reviewByTeamLead(
        attendanceId: attendanceId,
        reviewedBy: widget.user.uid,
      );

      await _loadTeamMembers();

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked as reviewed.')),
      );
    } catch (e, stackTrace) {
      debugPrint('TEAM LEAD REVIEW ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to review attendance: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingEmployeeId = null;
        });
      }
    }
  }

  // ==================================================
  // TEAM LEAD CHECK-IN
  // ==================================================

  // ==================================================
  // TEAM LEAD CHECK-IN
  // ==================================================

  Future<void> _checkIn() async {
    if (_myAttendance != null || _isGettingLocation) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // ------------------------------------------
      // 1. GET CURRENT GPS LOCATION
      // ------------------------------------------

      final position = await _locationService.getCurrentLocation();

      if (!mounted) return;

      // ------------------------------------------
      // 2. VALIDATE TEAM LOCATION
      // ------------------------------------------
      //
      // Team Lead:
      //   Team
      //      ↓
      //   Current Team Location
      //      ↓
      //   GPS Distance
      //      ↓
      //   Radius Check
      //
      final attendanceLocationType = await _attendanceService
          .validateAttendanceLocation(
            user: widget.user,
            latitude: position.latitude,
            longitude: position.longitude,
          );

      // ------------------------------------------
      // 3. GET CURRENT TEAM LOCATION / AREA
      // ------------------------------------------

      String area = '';

      if (attendanceLocationType == 'field') {
        final teamLocation = await _attendanceService.getCurrentLocationForUser(
          widget.user,
        );

        if (teamLocation != null) {
          area = teamLocation.locationName;
        }
      }

      if (!mounted) return;

      // ------------------------------------------
      // 4. CONFIRM ATTENDANCE
      // ------------------------------------------

      final note = await showDialog<String>(
        context: context,
        builder: (_) {
          return CheckInConfirmationDialog(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            onViewMap: _openGoogleMaps,
          );
        },
      );

      if (!mounted || note == null) {
        return;
      }

      // ------------------------------------------
      // 5. CREATE ATTENDANCE
      // ------------------------------------------

      await _attendanceService.createAttendance(
        userId: widget.user.uid,
        employeeId: widget.user.employeeId,
        teamId: widget.user.teamId,
        teamLeadId: widget.user.teamLeadId,
        areaManagerId: widget.user.adminId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        note: note,
        attendanceLocationType: attendanceLocationType,
        area: area,
      );

      // ------------------------------------------
      // 6. REFRESH MY ATTENDANCE
      // ------------------------------------------

      await _loadMyAttendance();

      if (mounted) {
        setState(() {});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance submitted successfully.')),
      );
    } catch (e, stackTrace) {
      debugPrint('TEAM LEAD CHECK-IN ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final error = e.toString();

      String message;

      if (error.contains('No field location has been assigned to your team')) {
        message =
            'No field location has been assigned to your team. Please contact your Area Manager.';
      } else if (error.contains('outside your assigned field location')) {
        message =
            'You are outside your assigned field location. Please move to the assigned location and try again.';
      } else {
        message = 'Attendance error: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // ==================================================
  // GOOGLE MAPS
  // ==================================================

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$latitude,$longitude',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open Google Maps.')),
        );
      }
    } catch (e) {
      debugPrint('GOOGLE MAPS ERROR: $e');
    }
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
        title: const Text('Team Lead Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Attendance History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceHistoryScreen(user: widget.user),
                ),
              );
            },
          ),

          IconButton(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
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
                padding: const EdgeInsets.all(16),
                children: [
                  DashboardGreeting(
                    name: widget.user.name,
                    subtitle: 'Team ${widget.user.name}',
                  ),

                  const SizedBox(height: 22),

                  _buildMyAttendance(),

                  const SizedBox(height: 26),

                  const Text(
                    'Team Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 12),

                  AttendanceStats(
                    total: _totalMembers,
                    checkedIn: _checkedIn,
                    onTime: _onTime,
                    late: _late,
                    pending: _pending,
                    approved: _approved,
                    rejected: _rejected,
                    missing: _missing,
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    'Team Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 12),

                  if (_members.isEmpty) _buildEmptyState(),

                  ..._members.map(_buildMemberCard),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ==================================================
  // MY ATTENDANCE
  // ==================================================

  Widget _buildMyAttendance() {
    final status =
        _myAttendance?['attendanceStatus']?.toString() ??
        _myAttendance?['status']?.toString();

    final timing = _myAttendance?['timingStatus']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Attendance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        AttendanceStatusCard(
          status: status,
          isLoading: false,
          isGettingLocation: _isGettingLocation,
          onCheckIn: _checkIn,
        ),

        if (timing != null) ...[
          const SizedBox(height: 12),
          AttendanceTimingCard(
            timingStatus: timing,
            checkInTime: _formatTime(_myAttendance?['checkInTime']),
          ),
        ],
      ],
    );
  }

  // ==================================================
  // MEMBER CARD
  // ==================================================

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    final uid = member['uid'].toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TeamMemberAttendanceCard(
        employeeName: member['name'].toString(),
        employeeId: member['employeeId'].toString(),

        checkInTime: _formatTime(attendance?['checkInTime']),

        timingStatus: _timingStatus(attendance),

        approvalStatus: _approvalStatus(attendance),

        teamLeadReviewed: _teamLeadReviewed(attendance),

        hasAttendance: attendance != null,

        isUpdating: _updatingEmployeeId == uid,

        onReview: attendance == null || _teamLeadReviewed(attendance)
            ? null
            : () {
                _reviewAttendance(uid);
              },

        onViewLocation: attendance == null
            ? null
            : () {
                _viewLocation(attendance);
              },
      ),
    );
  }

  // ==================================================
  // LOCATION
  // ==================================================

  Future<void> _viewLocation(Map<String, dynamic> attendance) async {
    final latitude = (attendance['latitude'] as num?)?.toDouble();

    final longitude = (attendance['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data is not available.')),
      );

      return;
    }

    await _openGoogleMaps(latitude, longitude);
  }

  // ==================================================
  // TIME
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

  // ==================================================
  // EMPTY STATE
  // ==================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, size: 40, color: Colors.black38),
          SizedBox(height: 10),
          Text('No team members found.'),
        ],
      ),
    );
  }
}
