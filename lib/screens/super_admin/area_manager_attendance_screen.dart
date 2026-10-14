import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../services/super_admin_service.dart';

class AreaManagerAttendanceScreen extends StatefulWidget {
  final AppUser user;

  const AreaManagerAttendanceScreen({super.key, required this.user});

  @override
  State<AreaManagerAttendanceScreen> createState() =>
      _AreaManagerAttendanceScreenState();
}

class _AreaManagerAttendanceScreenState
    extends State<AreaManagerAttendanceScreen> {
  final SuperAdminService _service = SuperAdminService();

  bool _isLoading = true;

  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final records = await _service.getAreaManagerAttendance();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AREA MANAGER ATTENDANCE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load attendance: $e')));
    }
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

  Future<void> _openLocation(Map<String, dynamic> record) async {
    final latitude = record['latitude'];
    final longitude = record['longitude'];

    if (latitude == null || longitude == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location information is not available.')),
      );

      return;
    }

    final lat = double.tryParse(latitude.toString());
    final lng = double.tryParse(longitude.toString());

    if (lat == null || lng == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid location information.')),
      );

      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open location.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open location: $e')));
    }
  }

  String _getAttendanceStatus(Map<String, dynamic> record) {
    return record['attendanceStatus']?.toString() ??
        record['approvalStatus']?.toString() ??
        'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Area Manager Attendance',
          style: TextStyle(
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
              _buildHeader(_records.length),

              const SizedBox(height: 18),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_records.isEmpty)
                _emptyState()
              else
                _buildTable(_records),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            child: const Icon(
              Icons.manage_accounts_outlined,
              color: Color(0xFF155084),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Area Manager Attendance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172B4D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review and approve area manager attendance.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7A8491)),
                ),
              ],
            ),
          ),

          Text(
            '$total Records',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF155084),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> records) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 42,
            horizontalMargin: 24,
            headingRowHeight: 54,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 76,
            dividerThickness: 0.7,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFBFCFE)),
            columns: const [
              DataColumn(label: Text('EMPLOYEE ID')),
              DataColumn(label: Text('NAME')),
              DataColumn(label: Text('ROLE')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('LOCATION')),
              DataColumn(label: Text('APPROVAL')),
            ],
            rows: records.map((record) {
              final checkInTime = record['checkInTime'] as DateTime;

              final status = _getAttendanceStatus(record);

              return DataRow(
                cells: [
                  DataCell(Text(record['employeeId']?.toString() ?? '-')),

                  DataCell(Text(record['name']?.toString() ?? '-')),

                  const DataCell(Text('Area Manager')),

                  DataCell(_statusCell(checkInTime)),

                  DataCell(_locationCell(() => _openLocation(record))),

                  DataCell(
                    _approvalCell(
                      status: status,
                      onApprove: () {
                        _approveAttendance(record['attendanceId'].toString());
                      },
                      onReject: () {
                        _rejectAttendance(record['attendanceId'].toString());
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusCell(DateTime checkInTime) {
    final cutoff = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      10,
      30,
    );

    final isLate = checkInTime.isAfter(cutoff);

    final statusColor = isLate
        ? const Color(0xFFE53935)
        : const Color(0xFF35A853);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 7),

            Text(
              isLate ? 'Late' : 'On Time',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          '${checkInTime.day.toString().padLeft(2, '0')} '
          '${_month(checkInTime.month)} • '
          '${_formatTime(checkInTime)}',
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A8491)),
        ),
      ],
    );
  }

  Widget _locationCell(VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 17, color: Color(0xFF155084)),

          SizedBox(width: 5),

          Text(
            'View',
            style: TextStyle(fontSize: 12, color: Color(0xFF155084)),
          ),

          SizedBox(width: 5),

          Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF155084)),
        ],
      ),
    );
  }

  Widget _approvalCell({
    required String status,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    if (status == 'approved') {
      return _statusBadge(
        icon: Icons.check_rounded,
        text: 'Approved',
        color: const Color(0xFF35A853),
      );
    }

    if (status == 'rejected') {
      return _statusBadge(
        icon: Icons.close_rounded,
        text: 'Rejected',
        color: const Color(0xFFE53935),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(Icons.close_rounded, const Color(0xFFE53935), onReject),

        const SizedBox(width: 10),

        _actionButton(Icons.check_rounded, const Color(0xFF35A853), onApprove),
      ],
    );
  }

  Widget _statusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),

          const SizedBox(width: 5),

          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: color),
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
            'No area manager attendance found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
            ),
          ),

          SizedBox(height: 6),

          Text(
            'No Area Manager has checked in today.',
            style: TextStyle(fontSize: 11, color: Color(0xFF7A8491)),
          ),
        ],
      ),
    );
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
