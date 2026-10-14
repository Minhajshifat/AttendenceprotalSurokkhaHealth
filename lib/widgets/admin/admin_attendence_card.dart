import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAttendanceCard extends StatelessWidget {
  final String employeeName;
  final String employeeId;
  final String checkInTime;
  final String? timingStatus;
  final String? attendanceStatus;
  final bool hasAttendance;
  final bool teamLeadReviewed;
  final bool areaManagerReviewed;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onViewLocation;

  const AdminAttendanceCard({
    super.key,
    required this.employeeName,
    required this.employeeId,
    required this.checkInTime,
    required this.timingStatus,
    required this.attendanceStatus,
    required this.hasAttendance,
    required this.teamLeadReviewed,
    required this.areaManagerReviewed,
    this.onApprove,
    this.onReject,
    this.onViewLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildAttendanceInfo(),

          if (hasAttendance) ...[
            const SizedBox(height: 9),
            _buildReviewInfo(),
            const SizedBox(height: 14),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            employeeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          employeeId,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceInfo() {
    if (!hasAttendance) {
      return Row(
        children: [
          const Icon(Icons.person_off_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            'No attendance submitted',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _InfoRow(
          label: 'Check-in',
          value: checkInTime,
          icon: Icons.access_time_rounded,
        ),
        const SizedBox(height: 9),
        _InfoRow(
          label: 'Timing',
          value: _timingLabel,
          icon: _timingIcon,
          valueColor: _timingColor,
        ),
        const SizedBox(height: 9),
        _InfoRow(
          label: 'Attendance',
          value: _attendanceLabel,
          icon: _attendanceIcon,
          valueColor: _attendanceColor,
        ),
      ],
    );
  }

  Widget _buildReviewInfo() {
    return Column(
      children: [
        const SizedBox(height: 4),
        _InfoRow(
          label: 'Team Lead',
          value: teamLeadReviewed ? 'Reviewed' : 'Not Reviewed',
          icon: teamLeadReviewed
              ? Icons.check_circle_outline_rounded
              : Icons.more_horiz_rounded,
          valueColor: teamLeadReviewed
              ? const Color(0xFF43C047)
              : Colors.orange,
        ),
        const SizedBox(height: 9),
        _InfoRow(
          label: 'Area Manager',
          value: areaManagerReviewed ? 'Reviewed' : 'Not Reviewed',
          icon: areaManagerReviewed
              ? Icons.check_circle_outline_rounded
              : Icons.more_horiz_rounded,
          valueColor: areaManagerReviewed
              ? const Color(0xFF43C047)
              : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActions() {
    final status = attendanceStatus?.toLowerCase() ?? 'pending';
    final isPending = status == 'pending';

    return Column(
      children: [
        if (isPending)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF43C047),
                    side: const BorderSide(color: Color(0xFF43C047)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (isPending) const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onViewLocation,
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('View Location'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF155084),
            ),
          ),
        ),
      ],
    );
  }

  String get _timingLabel {
    switch (timingStatus?.toLowerCase()) {
      case 'on_time':
        return 'On Time';

      case 'late':
        return 'Late';

      default:
        return 'Unknown';
    }
  }

  IconData get _timingIcon {
    if (timingStatus?.toLowerCase() == 'late') {
      return Icons.schedule_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  Color get _timingColor {
    if (timingStatus?.toLowerCase() == 'late') {
      return Colors.red;
    }

    return const Color(0xFF43C047);
  }

  String get _attendanceLabel {
    switch (attendanceStatus?.toLowerCase()) {
      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'pending':
        return 'Pending';

      default:
        return 'Unknown';
    }
  }

  IconData get _attendanceIcon {
    switch (attendanceStatus?.toLowerCase()) {
      case 'approved':
        return Icons.verified_outlined;

      case 'rejected':
        return Icons.cancel_outlined;

      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  Color get _attendanceColor {
    switch (attendanceStatus?.toLowerCase()) {
      case 'approved':
        return const Color(0xFF43C047);

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valueColor ?? const Color(0xFF155084)),
        const SizedBox(width: 9),
        Text(
          '$label:',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF172B4D),
            ),
          ),
        ),
      ],
    );
  }
}
