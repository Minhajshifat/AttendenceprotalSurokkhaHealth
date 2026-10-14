import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamMemberAttendanceCard extends StatelessWidget {
  final String employeeName;
  final String employeeId;
  final String checkInTime;
  final String? timingStatus;
  final String? approvalStatus;
  final bool teamLeadReviewed;
  final bool hasAttendance;
  final bool isUpdating;
  final VoidCallback? onReview;
  final VoidCallback? onViewLocation;

  const TeamMemberAttendanceCard({
    super.key,
    required this.employeeName,
    required this.employeeId,
    required this.checkInTime,
    required this.timingStatus,
    required this.approvalStatus,
    required this.teamLeadReviewed,
    required this.hasAttendance,
    required this.isUpdating,
    this.onReview,
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

          if (hasAttendance) _buildAttendanceInfo() else _buildMissing(),

          if (hasAttendance) ...[
            const SizedBox(height: 14),
            _buildReviewStatus(),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  // ==================================================
  // HEADER
  // ==================================================

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

  // ==================================================
  // ATTENDANCE INFO
  // ==================================================

  Widget _buildAttendanceInfo() {
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

  // ==================================================
  // MISSING
  // ==================================================

  Widget _buildMissing() {
    return Row(
      children: [
        const Icon(Icons.person_off_outlined, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text(
          'Missing',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==================================================
  // REVIEW STATUS
  // ==================================================

  Widget _buildReviewStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: teamLeadReviewed
            ? const Color(0xFFEAF8EA)
            : const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            teamLeadReviewed ? Icons.verified_outlined : Icons.pending_outlined,
            size: 18,
            color: teamLeadReviewed ? const Color(0xFF43C047) : Colors.orange,
          ),

          const SizedBox(width: 8),

          Text(
            'Team Lead Review',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
          ),

          const Spacer(),

          Text(
            teamLeadReviewed ? 'Reviewed' : 'Not Reviewed',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: teamLeadReviewed ? const Color(0xFF43C047) : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // ACTIONS
  // ==================================================

  Widget _buildActions() {
    return Column(
      children: [
        if (!teamLeadReviewed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUpdating ? null : onReview,
              icon: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isUpdating ? 'Reviewing...' : 'Mark as Reviewed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155084),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),

        if (!teamLeadReviewed) const SizedBox(height: 8),

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

  // ==================================================
  // TIMING
  // ==================================================

  String get _timingLabel {
    switch (timingStatus) {
      case 'on_time':
        return 'On Time';

      case 'late':
        return 'Late';

      default:
        return 'Unknown';
    }
  }

  IconData get _timingIcon {
    if (timingStatus == 'late') {
      return Icons.schedule_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  Color get _timingColor {
    if (timingStatus == 'late') {
      return Colors.red;
    }

    return const Color(0xFF43C047);
  }

  // ==================================================
  // ATTENDANCE STATUS
  // ==================================================

  String get _attendanceLabel {
    switch (approvalStatus) {
      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'pending':
        return 'Pending';

      default:
        return 'Pending';
    }
  }

  IconData get _attendanceIcon {
    switch (approvalStatus) {
      case 'approved':
        return Icons.verified_outlined;

      case 'rejected':
        return Icons.cancel_outlined;

      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  Color get _attendanceColor {
    switch (approvalStatus) {
      case 'approved':
        return const Color(0xFF43C047);

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }
}

// ==================================================
// INFO ROW
// ==================================================

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
