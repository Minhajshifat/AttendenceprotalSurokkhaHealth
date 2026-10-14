import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surokkha_attendance/services/super_admin_service.dart';
import 'package:surokkha_attendance/widgets/super_admin/attendance_day_details_screen.dart';
import 'package:file_saver/file_saver.dart';
import '../../services/attendance_export_service.dart';

class AttendanceHistoryScreenSuper extends StatefulWidget {
  const AttendanceHistoryScreenSuper({super.key});

  @override
  State<AttendanceHistoryScreenSuper> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreenSuper> {
  final SuperAdminService _adminService = SuperAdminService();

  bool _isLoading = true;

  List<Map<String, dynamic>> _dates = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dates = await _adminService.getAttendanceHistoryDatesByMonth(
        _selectedMonth,
      );

      if (!mounted) return;

      setState(() {
        _dates = dates;
      });
    } catch (e, stackTrace) {
      debugPrint('ATTENDANCE HISTORY ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load attendance history: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });

    _loadHistory();
  }

  void _nextMonth() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

    if (nextMonth.isAfter(currentMonth)) {
      return;
    }

    setState(() {
      _selectedMonth = nextMonth;
    });

    _loadHistory();
  }

  String _formatMonth(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
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

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth =
        _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        title: Text(
          'Attendance History',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Export Monthly Excel',
            onPressed: _isLoading ? null : _exportMonthlyAttendance,
            icon: const Icon(Icons.download_rounded, color: Color(0xFF155084)),
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF155084)),
          ),
        ],
      ),

      body: Column(
        children: [
          // ==========================================
          // MONTH SELECTOR
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _previousMonth,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF155084),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      _formatMonth(_selectedMonth),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172B4D),
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _isLoading || isCurrentMonth ? null : _nextMonth,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isCurrentMonth
                        ? Colors.grey.shade300
                        : const Color(0xFF155084),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // HISTORY LIST
          // ==========================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _dates.isEmpty
                ? Center(
                    child: Text(
                      'No attendance history found for ${_formatMonth(_selectedMonth)}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _dates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _dates[index];

                        final date = item['date']?.toString() ?? '';

                        final count = item['count'] as int? ?? 0;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AttendanceDayDetailsScreen(date: date),
                              ),
                            );
                          },

                          child: Ink(
                            padding: const EdgeInsets.all(16),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE3E8EF),
                              ),
                            ),

                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,

                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF3FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  child: const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFF155084),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        _formatDate(date),

                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF172B4D),
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        '$count employee${count == 1 ? '' : 's'} checked in',

                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF155084),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportMonthlyAttendance() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final records = await _adminService.getMonthlyAttendanceForExport(
        _selectedMonth,
      );

      if (records.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No attendance found for ${_formatMonth(_selectedMonth)}',
            ),
          ),
        );

        return;
      }

      final bytes = await AttendanceExportService.generateMonthlyExcel(
        month: _selectedMonth,
        records: records,
      );

      final month = _selectedMonth.month.toString().padLeft(2, '0');

      final fileName = 'attendance_${_selectedMonth.year}_$month';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance exported successfully')),
      );
    } catch (e, stackTrace) {
      debugPrint('MONTHLY EXPORT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export attendance: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
