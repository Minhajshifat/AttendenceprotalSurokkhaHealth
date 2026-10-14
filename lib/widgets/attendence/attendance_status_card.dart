import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceStatusCard extends StatelessWidget {
  final String? status;
  final bool isLoading;
  final bool isGettingLocation;
  final VoidCallback? onCheckIn;

  const AttendanceStatusCard({
    super.key,
    required this.status,
    required this.isLoading,
    required this.isGettingLocation,
    required this.onCheckIn,
  });

  static const sapphireBlue = Color(0xFF155084);
  static const kellyGreen = Color(0xFF43C047);
  static const textColor = Color(0xFF172B4D);

  Color get statusColor {
    switch (status) {
      case 'approved':
        return kellyGreen;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return sapphireBlue;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String get title {
    if (isLoading) {
      return 'Checking attendance...';
    }

    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Attendance Approved';
      case 'rejected':
        return 'Attendance Rejected';
      default:
        return 'Not checked in';
    }
  }

  String get subtitle {
    if (isLoading) {
      return 'Please wait...';
    }

    switch (status) {
      case 'pending':
        return 'Waiting for Team Lead approval';
      case 'approved':
        return 'Your attendance has been approved';
      case 'rejected':
        return 'Your attendance was rejected';
      default:
        return 'You have not submitted attendance today';
    }
  }

  String get buttonText {
    if (isLoading) return 'Checking...';
    if (isGettingLocation) return 'Getting Location...';

    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Attendance Approved';
      case 'rejected':
        return 'Attendance Rejected';
      default:
        return 'Check In';
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedIn = status != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading || isGettingLocation || checkedIn
                  ? null
                  : onCheckIn,
              icon: isGettingLocation
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      checkedIn
                          ? Icons.check_rounded
                          : Icons.location_on_outlined,
                    ),
              label: Text(
                buttonText,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: checkedIn ? statusColor : sapphireBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: checkedIn
                    ? statusColor
                    : sapphireBlue.withValues(alpha: 0.7),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
