import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceTimingCard extends StatelessWidget {
  final String? timingStatus;
  final String checkInTime;

  const AttendanceTimingCard({
    super.key,
    required this.timingStatus,
    required this.checkInTime,
  });

  static const kellyGreen = Color(0xFF43C047);
  static const textColor = Color(0xFF172B4D);

  Color get color {
    switch (timingStatus) {
      case 'on_time':
        return kellyGreen;
      case 'late':
        return Colors.red;
      default:
        return Colors.black45;
    }
  }

  IconData get icon {
    switch (timingStatus) {
      case 'on_time':
        return Icons.check_circle_outline;
      case 'late':
        return Icons.schedule_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String get label {
    switch (timingStatus) {
      case 'on_time':
        return 'On Time';
      case 'late':
        return 'Late';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Timing',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            checkInTime,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
