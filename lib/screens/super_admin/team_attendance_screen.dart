import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/super_admin_service.dart';
import '../../widgets/super_admin/approval_team_section.dart';
import '../../widgets/super_admin/attendance_table.dart';

class TeamAttendanceScreen extends StatefulWidget {
  final AppUser user;
  final String teamId;
  final String teamName;
  final String teamLeadName;

  const TeamAttendanceScreen({
    super.key,
    required this.user,
    required this.teamId,
    required this.teamName,
    required this.teamLeadName,
  });

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  final SuperAdminService _service = SuperAdminService();

  bool _isLoading = true;
  bool _isApprovingAll = false;

  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final records = await _service.getTeamAttendance(teamId: widget.teamId);

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('TEAM ATTENDANCE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load attendance: $e')));
    }
  }

  int get _pendingCount {
    return _records.where((record) {
      final status = record['attendanceStatus']?.toString() ?? 'pending';

      return status == 'pending';
    }).length;
  }

  Future<void> _approveAttendance(String attendanceId) async {
    try {
      await _service.approveAttendance(
        attendanceId: attendanceId,
        approvedBy: widget.user.uid,
      );

      await _loadAttendance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance approved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to approve attendance: $e')),
      );
    }
  }

  Future<void> _rejectAttendance(String attendanceId) async {
    try {
      await _service.rejectAttendance(
        attendanceId: attendanceId,
        rejectedBy: widget.user.uid,
        reason: 'Rejected by Super Admin',
      );

      await _loadAttendance();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance rejected.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to reject attendance: $e')),
      );
    }
  }

  Future<void> _approveAllAttendance() async {
    if (_isApprovingAll) {
      return;
    }

    if (_pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending attendance to approve.')),
      );
      return;
    }

    try {
      setState(() {
        _isApprovingAll = true;
      });

      final count = await _service.approveAllTeamAttendance(
        teamId: widget.teamId,
        approvedBy: widget.user.uid,
      );

      await _loadAttendance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count attendance record(s) approved successfully.'),
        ),
      );
    } catch (e) {
      debugPrint('APPROVE ALL ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to approve all attendance: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApprovingAll = false;
        });
      }
    }
  }

  Future<void> _resetAttendance(Map<String, dynamic> record) async {
    final userId = record['userId']?.toString();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify this employee.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Attendance'),
          content: Text(
            'Are you sure you want to reset attendance for '
            '${record['name'] ?? 'this employee'}?\n\n'
            'The employee will be able to submit attendance again today.',
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
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final attendanceId = record['attendanceId']?.toString();

      if (attendanceId == null || attendanceId.isEmpty) {
        throw Exception('Attendance ID not found.');
      }

      await _service.resetAttendance(attendanceId: attendanceId);

      await _loadAttendance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance has been reset successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to reset attendance: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${widget.teamName} Attendance',
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAttendance,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ApprovalTeamSection(
                teamName: widget.teamName,
                teamLeadName: widget.teamLeadName,
                pendingCount: _pendingCount,
                onApproveAll: _isApprovingAll ? () {} : _approveAllAttendance,
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_records.isEmpty)
                _emptyState()
              else
                AttendanceTable(
                  records: _records,
                  onApprove: _approveAttendance,
                  onReject: _rejectAttendance,
                  onReset: _resetAttendance,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 40, color: Color(0xFF98A1AD)),
          SizedBox(height: 12),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }
}
