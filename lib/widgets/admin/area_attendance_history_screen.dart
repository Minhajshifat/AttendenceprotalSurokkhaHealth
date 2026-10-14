import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_user.dart';
import '../../services/admin_service.dart';

class AreaAttendanceHistoryScreen extends StatefulWidget {
  final AppUser user;

  const AreaAttendanceHistoryScreen({super.key, required this.user});

  @override
  State<AreaAttendanceHistoryScreen> createState() =>
      _AreaAttendanceHistoryScreenState();
}

class _AreaAttendanceHistoryScreenState
    extends State<AreaAttendanceHistoryScreen> {
  final AdminService _adminService = AdminService();

  bool _isLoading = true;

  List<Map<String, dynamic>> _history = [];

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
      final history = await _adminService.getAreaAttendanceHistory(
        teamIds: widget.user.teamIds,
        days: 30,
      );

      if (!mounted) return;

      setState(() {
        _history = history;
      });
    } catch (e) {
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

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Unknown date';
    }

    try {
      final dateTime = value.toDate();

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;

      return '$day/$month/$year';
    } catch (_) {
      return 'Unknown date';
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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
              child: Text(
                'No attendance history found',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: _history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final attendance = _history[index];

                  final timingStatus =
                      attendance['timingStatus']?.toString() ?? '';

                  final attendanceStatus =
                      attendance['attendanceStatus']?.toString() ??
                      attendance['status']?.toString() ??
                      'pending';

                  final isOnTime = timingStatus == 'on_time';

                  final normalizedStatus = attendanceStatus.toLowerCase();

                  final isApproved = normalizedStatus == 'approved';

                  final isRejected = normalizedStatus == 'rejected';

                  final statusColor = isApproved
                      ? const Color(0xFF43C047)
                      : isRejected
                      ? Colors.red
                      : Colors.orange;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE3E8EF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icons.person_outline,
                                color: Color(0xFF155084),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attendance['name']?.toString() ?? 'Unknown',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF172B4D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    attendance['employeeId']?.toString() ?? '—',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                attendanceStatus.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        const Divider(),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Color(0xFF155084),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(attendance['checkInTime']),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),

                            const Spacer(),

                            const Icon(
                              Icons.access_time_outlined,
                              size: 16,
                              color: Color(0xFF155084),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(attendance['checkInTime']),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF172B4D),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          isOnTime ? 'On Time' : 'Late',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isOnTime
                                ? const Color(0xFF43C047)
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
