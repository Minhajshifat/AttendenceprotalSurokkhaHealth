import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMemberAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isUpdating;
  final bool canReview;
  final VoidCallback onReview;

  const TeamMemberAttendanceCard({
    super.key,
    required this.member,
    required this.isUpdating,
    required this.canReview,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    final isTeamLead = member['isTeamLead'] == true;

    final name = member['name']?.toString() ?? 'Unknown';

    final employeeId = member['employeeId']?.toString() ?? '—';

    final role = isTeamLead ? 'Team Lead' : 'Agent';

    final hasAttendance = attendance != null;

    final teamLeadReviewed = attendance?['teamLeadReviewed'] == true;

    final areaManagerReviewed = attendance?['areaManagerReviewed'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF172B4D),
                  ),
                ),
              ),
              Text(
                employeeId,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            role,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.black45),
          ),

          const SizedBox(height: 14),

          if (!hasAttendance)
            _buildMissing()
          else ...[
            _InfoRow(
              label: 'Check-in',
              value: _formatTime(attendance['checkInTime']),
              icon: Icons.access_time_rounded,
            ),

            const SizedBox(height: 9),

            _InfoRow(
              label: 'Timing',
              value: _timingLabel(attendance['timingStatus']?.toString()),
              icon: _timingIcon(attendance['timingStatus']?.toString()),
              valueColor: _timingColor(attendance['timingStatus']?.toString()),
            ),

            const SizedBox(height: 9),

            _InfoRow(
              label: 'Attendance',
              value: _attendanceLabel(attendance),
              icon: Icons.assignment_outlined,
              valueColor: _attendanceColor(attendance),
            ),

            const SizedBox(height: 14),

            _ReviewRow(
              label: 'Team Lead',
              reviewed: isTeamLead ? true : teamLeadReviewed,
            ),

            const SizedBox(height: 7),

            _ReviewRow(label: 'Area Manager', reviewed: areaManagerReviewed),

            const SizedBox(height: 12),

            if (canReview)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUpdating ? null : onReview,
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

            if (canReview) const SizedBox(height: 6),

            if (hasAttendance)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    _openLocation(context, attendance);
                  },
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('View Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF155084),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissing() {
    return Row(
      children: [
        const Icon(Icons.person_off_outlined, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          'No attendance submitted',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _openLocation(
    BuildContext context,
    Map<String, dynamic> attendance,
  ) async {
    final latitude = (attendance['latitude'] as num?)?.toDouble();

    final longitude = (attendance['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location data is not available.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$latitude,$longitude',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
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
      return 'Processing...';
    }
  }

  String _timingLabel(String? status) {
    switch (status) {
      case 'on_time':
        return 'On Time';
      case 'late':
        return 'Late';
      default:
        return 'Unknown';
    }
  }

  IconData _timingIcon(String? status) {
    return status == 'late'
        ? Icons.schedule_rounded
        : Icons.check_circle_outline_rounded;
  }

  Color _timingColor(String? status) {
    switch (status) {
      case 'on_time':
        return const Color(0xFF43C047);
      case 'late':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  String _attendanceLabel(Map<String, dynamic>? attendance) {
    final status =
        attendance?['attendanceStatus']?.toString() ??
        attendance?['status']?.toString();

    switch (status) {
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

  Color _attendanceColor(Map<String, dynamic>? attendance) {
    final status =
        attendance?['attendanceStatus']?.toString() ??
        attendance?['status']?.toString();

    switch (status) {
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

class _ReviewRow extends StatelessWidget {
  final String label;
  final bool reviewed;

  const _ReviewRow({required this.label, required this.reviewed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          reviewed ? Icons.verified_outlined : Icons.pending_outlined,
          size: 17,
          color: reviewed ? const Color(0xFF43C047) : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
        ),
        const Spacer(),
        Text(
          reviewed ? 'Reviewed' : 'Not Reviewed',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: reviewed ? const Color(0xFF43C047) : Colors.orange,
          ),
        ),
      ],
    );
  }
}
