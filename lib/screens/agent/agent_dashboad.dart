import 'package:flutter/material.dart';
import 'package:surokkha_attendance/screens/attendance_history_screen.dart';
import 'package:surokkha_attendance/screens/leave/leave_screen.dart';
import 'package:surokkha_attendance/widgets/logout_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../models/app_user.dart';
import '../../services/attendence_service.dart';
import '../../services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/attendence/attendance_details_card.dart';
import '../../widgets/attendence/attendance_status_card.dart';
import '../../widgets/attendence/attendance_timing_card.dart';
import '../../widgets/attendence/check_in_confirmation_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/dashboad/dashboard_greeting.dart';
import '../../widgets/dashboad/info_card.dart';

class AgentDashboard extends StatefulWidget {
  final AppUser user;

  const AgentDashboard({super.key, required this.user});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  static const sapphireBlue = Color(0xFF155084);

  static const kellyGreen = Color(0xFF43C047);

  final AttendanceService _attendanceService = AttendanceService();
  StreamSubscription<Map<String, dynamic>?>? _attendanceSubscription;

  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  bool _isGettingLocation = false;

  Map<String, dynamic>? _attendance;

  String? get _attendanceStatus {
    return _attendance?['attendanceStatus']?.toString() ??
        _attendance?['status']?.toString();
  }

  String? get _timingStatus {
    return _attendance?['timingStatus']?.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
    _listenToTodayAttendance();
  }

  // --------------------------------------------------
  // LOAD ATTENDANCE
  // --------------------------------------------------

  Future<void> _loadTodayAttendance() async {
    try {
      final attendance = await _attendanceService.getTodayAttendance(
        widget.user.uid,
      );

      if (!mounted) return;

      setState(() {
        _attendance = attendance;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('ATTENDANCE LOAD ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load attendance: $e')));
    }
  }

  void _listenToTodayAttendance() {
    _attendanceSubscription?.cancel();

    _attendanceSubscription = _attendanceService
        .getTodayAttendanceStream(widget.user.uid)
        .listen(
          (attendance) {
            debugPrint('========== REAL-TIME ATTENDANCE UPDATE ==========');
            debugPrint('Agent UID: ${widget.user.uid}');
            debugPrint('Attendance data: $attendance');
            debugPrint('Status: ${attendance?['attendanceStatus']}');
            debugPrint('===============================================');

            if (!mounted) return;

            setState(() {
              _attendance = attendance;
              _isLoading = false;
            });
          },
          onError: (error, stackTrace) {
            debugPrint('========== ATTENDANCE STREAM ERROR ==========');
            debugPrint('$error');

            final currentUser = FirebaseAuth.instance.currentUser;

            debugPrint('CURRENT AUTH USER: ${currentUser?.uid}');
            debugPrint('CURRENT AUTH EMAIL: ${currentUser?.email}');

            debugPrint('============================================');

            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });
          },
        );
  }

  // --------------------------------------------------
  // CHECK IN
  // --------------------------------------------------
  // --------------------------------------------------
  // CHECK IN
  // --------------------------------------------------
  // --------------------------------------------------
  // CHECK IN
  // --------------------------------------------------
  Future<void> _checkIn() async {
    if (_attendanceStatus != null || _isGettingLocation) {
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
      // Agent / Team Lead:
      //   Team -> Current Team Location -> Radius
      //
      // Area Manager:
      //   Unrestricted
      //----------------------
      //AREA TYPE
      // final attendanceLocationType = await _attendanceService
      //     .validateAttendanceLocation(
      //       user: widget.user,
      //       latitude: position.latitude,
      //       longitude: position.longitude,
      //     );
      //--------------------------------------------------------
      // 2. TEMPORARILY DISABLE ASSIGNED LOCATION VALIDATION
      // GPS check-in will continue, but assigned-area restriction is off.
      const String attendanceLocationType = 'field';
      // ------------------------------------------
      // 3. GET CURRENT TEAM LOCATION
      // ------------------------------------------
      String area = '';

      // if (attendanceLocationType == 'field') {
      //   final teamLocation = await _attendanceService.getCurrentLocationForUser(
      //     widget.user,
      //   );

      //   if (teamLocation != null) {
      //     area = teamLocation.locationName;
      //   }
      //}

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
            onViewMap: (latitude, longitude) {
              return _openGoogleMaps(latitude, longitude);
            },
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance submitted successfully.')),
      );
    } catch (e, stackTrace) {
      debugPrint('ATTENDANCE SUBMISSION ERROR: $e');

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
      } else if (error.contains('outside the office attendance area')) {
        message =
            'You are outside the office attendance area. Please move closer to the office and try again.';
      } else if (error.contains('Office location has not been configured')) {
        message =
            'Office location has not been configured yet. Please contact the Super Admin.';
      } else if (error.contains('Office location configuration is invalid')) {
        message =
            'Office location configuration is invalid. Please contact the Super Admin.';
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }

  // --------------------------------------------------
  // TIME FORMAT
  // --------------------------------------------------
  String _formatCheckInTime() {
    final value = _attendance?['checkInTime'];

    if (value == null) {
      return '—';
    }

    DateTime dateTime;

    try {
      dateTime = value.toDate();
    } catch (_) {
      return 'Processing...';
    }

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final horizontalPadding = width < 500 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text('Agent Dashboad'),

        actions: [
          IconButton(
            tooltip: 'Leave Request',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaveScreen(
                    userId: widget.user.uid,
                    employeeId: widget.user.employeeId,
                    employeeName: widget.user.name,
                    role: 'agent',
                    teamId: widget.user.teamId,
                    teamName: '',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.event_available_outlined,
              color: sapphireBlue,
            ),
          ),
          IconButton(
            tooltip: 'Attendance History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AttendanceHistoryScreen(user: widget.user),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, color: sapphireBlue),
          ),

          IconButton(
            onPressed: _isLoading ? null : _loadTodayAttendance,
            icon: const Icon(Icons.refresh_rounded, color: sapphireBlue),
          ),

          const LogoutButton(),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadTodayAttendance,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),

          children: [
            // ------------------------------
            // GREETING
            // ------------------------------
            DashboardGreeting(name: widget.user.name),

            const SizedBox(height: 24),

            // ------------------------------
            // ATTENDANCE STATUS
            // ------------------------------
            AttendanceStatusCard(
              status: _attendanceStatus,
              isLoading: _isLoading,
              isGettingLocation: _isGettingLocation,
              onCheckIn: _checkIn,
            ),

            // ------------------------------
            // TIMING
            // ------------------------------
            if (_timingStatus != null) ...[
              const SizedBox(height: 16),

              AttendanceTimingCard(
                timingStatus: _timingStatus,
                checkInTime: _formatCheckInTime(),
              ),
            ],

            const SizedBox(height: 20),

            // ------------------------------
            // EMPLOYEE INFORMATION
            // ------------------------------
            _buildEmployeeInformation(),

            const SizedBox(height: 24),

            // ------------------------------
            // TODAY'S ATTENDANCE
            // ------------------------------
            AttendanceDetailsCard(
              isLoading: _isLoading,

              attendance: _attendance,

              attendanceStatus: _attendanceStatus ?? '',

              timingStatus: _timingStatus ?? '',

              checkInTime: _formatCheckInTime(),

              onViewLocation: _attendance == null ? null : _viewSavedLocation,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPLOYEE INFORMATION
  // --------------------------------------------------
  Widget _buildTeamInfoCard() {
    if (widget.user.teamId.isEmpty) {
      return InfoCard(
        title: 'Team',
        value: 'Not Assigned',
        icon: Icons.groups_outlined,
        color: kellyGreen,
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.user.teamId)
          .get(),
      builder: (context, snapshot) {
        String teamName = 'Loading...';

        if (snapshot.hasError) {
          teamName = 'Unknown Team';
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            teamName = data?['name']?.toString() ?? 'Unknown Team';
          } else {
            teamName = 'Not Assigned';
          }
        }

        return InfoCard(
          title: 'Team',
          value: teamName,
          icon: Icons.groups_outlined,
          color: kellyGreen,
        );
      },
    );
  }

  Widget _buildEmployeeInformation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              InfoCard(
                title: 'Employee ID',
                value: widget.user.employeeId,
                icon: Icons.badge_outlined,
                color: sapphireBlue,
              ),

              const SizedBox(height: 12),

              _buildTeamInfoCard(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: InfoCard(
                title: 'Employee ID',
                value: widget.user.employeeId,
                icon: Icons.badge_outlined,
                color: sapphireBlue,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(child: _buildTeamInfoCard()),
          ],
        );
      },
    );
  }
  // --------------------------------------------------
  // SAVED LOCATION
  // --------------------------------------------------

  Future<void> _viewSavedLocation() async {
    final latitude = (_attendance?['latitude'] as num?)?.toDouble();

    final longitude = (_attendance?['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data is not available.')),
      );

      return;
    }

    await _openGoogleMaps(latitude, longitude);
  }
}
