import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/super_admin_service.dart';
import '../../services/attendance_export_service.dart';
import 'package:file_saver/file_saver.dart';

class AttendanceDayDetailsScreen extends StatefulWidget {
  final String date;

  const AttendanceDayDetailsScreen({super.key, required this.date});

  @override
  State<AttendanceDayDetailsScreen> createState() =>
      _AttendanceDayDetailsScreenState();
}

class _AttendanceDayDetailsScreenState
    extends State<AttendanceDayDetailsScreen> {
  final SuperAdminService _superAdminService = SuperAdminService();

  bool _isLoading = true;

  List<Map<String, dynamic>> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _superAdminService.getAttendanceByDate(widget.date);

      if (!mounted) return;

      setState(() {
        _attendanceRecords = records;
      });
    } catch (e, stackTrace) {
      debugPrint('DAY ATTENDANCE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load attendance: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');

      if (parts.length != 3) {
        return date;
      }

      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = parts[2];

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '$day ${months[month - 1]} $year';
    } catch (_) {
      return date;
    }
  }

  Future<void> _exportAttendance() async {
    try {
      final bytes = await AttendanceExportService.generateExcel(
        records: _attendanceRecords,
      );

      final fileName = 'attendance_${widget.date}';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance Excel file exported successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to export Excel: $e')));
    }
  }

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
      return '—';
    }
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'area_manager':
        return 'Area Manager';

      case 'team_lead':
        return 'Team Lead';

      case 'agent':
        return 'Agent';

      default:
        return role;
    }
  }

  String _timingLabel(String status) {
    switch (status) {
      case 'on_time':
        return 'On Time';

      case 'late':
        return 'Late';

      default:
        return '—';
    }
  }

  Color _timingColor(String status) {
    switch (status) {
      case 'on_time':
        return const Color(0xFF43C047);

      case 'late':
        return Colors.red;

      default:
        return Colors.black54;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'missing':
        return 'Missing';

      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF43C047);

      case 'rejected':
        return Colors.red;

      case 'missing':
        return Colors.grey;

      default:
        return Colors.orange;
    }
  }

  Future<void> _viewLocation(Map<String, dynamic> attendance) async {
    final latitude = (attendance['latitude'] as num?)?.toDouble();

    final longitude = (attendance['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data is not available.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
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
          _formatDate(widget.date),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Export Excel',
            onPressed: _isLoading ? null : _exportAttendance,
            icon: const Icon(Icons.download_rounded, color: Color(0xFF155084)),
          ),

          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF155084)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceRecords.isEmpty
          ? Center(
              child: Text(
                'No attendance found for this day',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAttendance,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummary(),

                  const SizedBox(height: 20),

                  Text(
                    'Employee Attendance',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF172B4D),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildAttendanceTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final total = _attendanceRecords.length;

    final checkedIn = _attendanceRecords.where((record) {
      final status =
          record['attendanceStatus']?.toString() ??
          record['status']?.toString() ??
          'pending';

      return status != 'missing';
    }).length;

    final onTime = _attendanceRecords.where((record) {
      return record['timingStatus']?.toString() == 'on_time';
    }).length;

    final late = _attendanceRecords.where((record) {
      return record['timingStatus']?.toString() == 'late';
    }).length;

    final missing = _attendanceRecords.where((record) {
      final status =
          record['attendanceStatus']?.toString() ??
          record['status']?.toString();

      return status == 'missing';
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          _summaryItem('Total', '$total', const Color(0xFF155084)),
          _summaryItem('Checked In', '$checkedIn', const Color(0xFF43C047)),
          _summaryItem('On Time', '$onTime', const Color(0xFF43C047)),
          _summaryItem('Late', '$late', Colors.red),
          _summaryItem('Missing', '$missing', const Color(0xFF7A8491)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  horizontalMargin: 28,
                  columnSpacing: 48,
                  headingRowHeight: 58,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 72,
                  dividerThickness: 1,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  headingTextStyle: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  dataTextStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF172B4D),
                  ),
                  columns: const [
                    DataColumn(
                      label: SizedBox(width: 150, child: Text('EMPLOYEE')),
                    ),
                    DataColumn(
                      label: SizedBox(width: 110, child: Text('ROLE')),
                    ),
                    DataColumn(
                      label: SizedBox(width: 110, child: Text('EMPLOYEE ID')),
                    ),
                    DataColumn(
                      label: SizedBox(width: 100, child: Text('CHECK-IN')),
                    ),
                    DataColumn(
                      label: SizedBox(width: 100, child: Text('TIMING')),
                    ),
                    DataColumn(
                      label: SizedBox(width: 110, child: Text('STATUS')),
                    ),
                    DataColumn(
                      label: SizedBox(width: 100, child: Text('LOCATION')),
                    ),
                  ],
                  rows: _attendanceRecords.map((record) {
                    final name = record['name']?.toString() ?? 'Unknown';

                    final role = record['role']?.toString() ?? 'Unknown';

                    final employeeId = record['employeeId']?.toString() ?? '—';

                    final timingStatus =
                        record['timingStatus']?.toString() ?? '';

                    final attendanceStatus =
                        record['attendanceStatus']?.toString() ??
                        record['status']?.toString() ??
                        'pending';

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFFEAF3FA),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF155084),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 105,
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF172B4D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _roleLabel(role),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            employeeId,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            _formatTime(record['checkInTime']),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _timingColor(timingStatus),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _timingLabel(timingStatus),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _timingColor(timingStatus),
                                ),
                              ),
                            ],
                          ),
                        ),

                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                attendanceStatus,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(attendanceStatus),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(attendanceStatus),
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          TextButton.icon(
                            onPressed: () {
                              _viewLocation(record);
                            },
                            icon: const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                            ),
                            label: const Text('View'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF155084),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
