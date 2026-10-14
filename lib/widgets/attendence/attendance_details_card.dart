import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceDetailsCard extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic>? attendance;
  final String attendanceStatus;
  final String timingStatus;
  final String checkInTime;
  final VoidCallback? onViewLocation;

  const AttendanceDetailsCard({
    super.key,
    required this.isLoading,
    required this.attendance,
    required this.attendanceStatus,
    required this.timingStatus,
    required this.checkInTime,
    required this.onViewLocation,
  });

  Color _statusColor() {
    switch (attendanceStatus) {
      case 'approved':
        return const Color(0xFF43C047);
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.black45;
    }
  }

  Color _timingColor() {
    switch (timingStatus) {
      case 'on_time':
        return const Color(0xFF43C047);
      case 'late':
        return Colors.red;
      default:
        return Colors.black45;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Attendance',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (attendance == null)
            _empty()
          else
            Column(
              children: [
                _row(
                  'Attendance',
                  attendanceStatus.toUpperCase(),
                  _statusColor(),
                ),
                const Divider(height: 24),
                _row(
                  'Timing',
                  timingStatus == 'on_time'
                      ? 'ON TIME'
                      : timingStatus.toUpperCase(),
                  _timingColor(),
                ),
                const Divider(height: 24),
                _row('Check-in', checkInTime, const Color(0xFF172B4D)),
                if (attendance?['latitude'] != null &&
                    attendance?['longitude'] != null) ...[
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onViewLocation,
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('View My Location'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 42,
            color: Colors.black26,
          ),
          const SizedBox(height: 10),
          Text(
            'No attendance submitted today',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
