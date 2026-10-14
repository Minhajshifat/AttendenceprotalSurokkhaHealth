import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surokkha_attendance/models/app_user.dart';
import 'package:surokkha_attendance/services/super_admin_service.dart';

class OfficeEmployeeAttendanceScreen extends StatefulWidget {
  final AppUser user;

  const OfficeEmployeeAttendanceScreen({super.key, required this.user});

  @override
  State<OfficeEmployeeAttendanceScreen> createState() =>
      _OfficeEmployeeAttendanceScreenState();
}

class _OfficeEmployeeAttendanceScreenState
    extends State<OfficeEmployeeAttendanceScreen> {
  final SuperAdminService _service = SuperAdminService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _records = [];
  String _selectedDesignation = 'All Designations';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _service.getOfficeEmployeeAttendance();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Office attendance error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load office employee attendance.';
      });
    }
  }

  List<String> get _designations {
    final values = _records
        .map((record) => record['designation']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ['All Designations', ...values];
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedDesignation == 'All Designations') {
      return _records;
    }

    return _records.where((record) {
      final designation = record['designation']?.toString().trim() ?? '';

      return designation == _selectedDesignation;
    }).toList();
  }

  int get _pendingCount {
    return _filteredRecords.where((record) {
      return record['attendanceStatus']?.toString() == 'pending';
    }).length;
  }

  int get _approvedCount {
    return _filteredRecords.where((record) {
      return record['attendanceStatus']?.toString() == 'approved';
    }).length;
  }

  int get _rejectedCount {
    return _filteredRecords.where((record) {
      return record['attendanceStatus']?.toString() == 'rejected';
    }).length;
  }

  int get _missingCount {
    return _filteredRecords.where((record) {
      return record['attendanceStatus']?.toString() == 'missing';
    }).length;
  }

  Future<void> _approve(String attendanceId) async {
    try {
      await _service.approveAttendance(
        attendanceId: attendanceId,
        approvedBy: widget.user.uid,
      );

      await _loadAttendance();

      if (!mounted) return;

      _showMessage('Attendance approved successfully.');
    } catch (e) {
      debugPrint('Approve error: $e');

      if (!mounted) return;

      _showMessage('Unable to approve attendance.', isError: true);
    }
  }

  Future<void> _reject(String attendanceId) async {
    final reason = await _showRejectDialog();

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      await _service.rejectAttendance(
        attendanceId: attendanceId,
        rejectedBy: widget.user.uid,
        reason: reason.trim(),
      );

      await _loadAttendance();

      if (!mounted) return;

      _showMessage('Attendance rejected.');
    } catch (e) {
      debugPrint('Reject error: $e');

      if (!mounted) return;

      _showMessage('Unable to reject attendance.', isError: true);
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Reject Attendance',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter rejection reason',
              hintStyle: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF98A1AD),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF35A853),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        title: Text(
          'Office Employee Attendance',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
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

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF687385),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155084),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      color: const Color(0xFF155084),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSummary(),
          const SizedBox(height: 16),
          _buildFilter(),
          const SizedBox(height: 16),
          _filteredRecords.isEmpty
              ? _buildEmptyState()
              : _buildAttendanceTable(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(
          title: 'Total',
          value: _filteredRecords.length,
          icon: Icons.people_outline_rounded,
        ),
        _summaryCard(
          title: 'Pending',
          value: _pendingCount,
          icon: Icons.pending_actions_rounded,
        ),
        _summaryCard(
          title: 'Approved',
          value: _approvedCount,
          icon: Icons.check_circle_outline_rounded,
        ),
        _summaryCard(
          title: 'Rejected',
          value: _rejectedCount,
          icon: Icons.cancel_outlined,
        ),
        _summaryCard(
          title: 'Missing',
          value: _missingCount,
          icon: Icons.person_off_outlined,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required int value,
    required IconData icon,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF155084)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: const Color(0xFF7A8491),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF172B4D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    final designations = _designations;

    if (designations.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            size: 20,
            color: Color(0xFF155084),
          ),
          const SizedBox(width: 10),
          Text(
            'Designation',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedDesignation,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              items: designations.map((designation) {
                return DropdownMenuItem(
                  value: designation,
                  child: Text(
                    designation,
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedDesignation = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    final records = _filteredRecords;

    return Container(
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
            columnSpacing: 30,
            horizontalMargin: 20,
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 70,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFBFCFE)),
            columns: const [
              DataColumn(label: Text('EMPLOYEE')),
              DataColumn(label: Text('DESIGNATION')),
              DataColumn(label: Text('CHECK-IN')),
              DataColumn(label: Text('TIMING')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: records.map<DataRow>((record) {
              final status =
                  record['attendanceStatus']?.toString() ?? 'missing';

              return DataRow(
                cells: [
                  DataCell(_employeeCell(record)),
                  DataCell(
                    Text(
                      record['designation']?.toString().isNotEmpty == true
                          ? record['designation'].toString()
                          : '-',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF172B4D),
                      ),
                    ),
                  ),
                  DataCell(_checkInCell(record['checkInTime'])),
                  DataCell(_timingBadge(record['timingStatus'])),
                  DataCell(_statusBadge(status)),
                  DataCell(_actionCell(record)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _employeeCell(Map<String, dynamic> record) {
    final name = record['name']?.toString() ?? '-';
    final employeeId = record['employeeId']?.toString() ?? '-';

    return SizedBox(
      width: 190,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
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
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF172B4D),
                  ),
                ),
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
        ],
      ),
    );
  }

  Widget _checkInCell(dynamic value) {
    if (value is! DateTime) {
      return Text(
        '—',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: const Color(0xFF98A1AD),
        ),
      );
    }

    final hour = value.hour > 12
        ? value.hour - 12
        : value.hour == 0
        ? 12
        : value.hour;

    final minute = value.minute.toString().padLeft(2, '0');

    final period = value.hour >= 12 ? 'PM' : 'AM';

    return Text(
      '$hour:$minute $period',
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF172B4D),
      ),
    );
  }

  Widget _timingBadge(dynamic value) {
    final timing = value?.toString() ?? '';

    if (timing.isEmpty) {
      return const Text('—');
    }

    final isLate = timing == 'late';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isLate ? const Color(0xFFFFF3E0) : const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isLate ? 'Late' : 'On Time',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isLate ? const Color(0xFFE67E22) : const Color(0xFF35A853),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    String label;
    Color background;
    Color foreground;

    switch (status) {
      case 'approved':
        label = 'Approved';
        background = const Color(0xFFEAF7EE);
        foreground = const Color(0xFF35A853);
        break;

      case 'rejected':
        label = 'Rejected';
        background = const Color(0xFFFFEEEE);
        foreground = const Color(0xFFE53935);
        break;

      case 'pending':
        label = 'Pending';
        background = const Color(0xFFFFF3E0);
        foreground = const Color(0xFFE67E22);
        break;

      default:
        label = 'Missing';
        background = const Color(0xFFF1F3F5);
        foreground = const Color(0xFF687385);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _actionCell(Map<String, dynamic> record) {
    final status = record['attendanceStatus']?.toString() ?? 'missing';

    if (status != 'pending') {
      return const Text('—', style: TextStyle(color: Color(0xFF98A1AD)));
    }

    final attendanceId = record['attendanceId']?.toString() ?? '';

    if (attendanceId.isEmpty) {
      return const Text('—');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Approve',
          onPressed: () => _approve(attendanceId),
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: Color(0xFF35A853),
          ),
        ),
        IconButton(
          tooltip: 'Reject',
          onPressed: () => _reject(attendanceId),
          icon: const Icon(
            Icons.cancel_outlined,
            size: 20,
            color: Color(0xFFE53935),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.business_outlined,
            size: 42,
            color: Color(0xFF98A1AD),
          ),
          const SizedBox(height: 10),
          Text(
            'No office employees found',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF687385),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
