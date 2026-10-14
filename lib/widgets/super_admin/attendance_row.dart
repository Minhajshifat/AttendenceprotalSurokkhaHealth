import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceRow {
  static DataRow build({
    required BuildContext context,
    required String employeeId,
    required String name,
    required String role,
    required DateTime checkInTime,
    required String timingStatus,
    required String attendanceStatus,
    required bool teamLeadReviewed,
    required bool areaManagerReviewed,
    required double? latitude,
    required double? longitude,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    required VoidCallback onReset,
  }) {
    return DataRow(
      cells: [
        DataCell(
          Text(employeeId, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),

        DataCell(Text(name)),

        DataCell(Text(_roleLabel(role))),

        DataCell(_checkInCell(checkInTime)),

        DataCell(_timingCell(timingStatus)),

        DataCell(_statusCell(attendanceStatus)),

        DataCell(_reviewCell(teamLeadReviewed, areaManagerReviewed)),

        DataCell(_locationCell(context, latitude, longitude)),

        DataCell(_approvalCell(attendanceStatus, onApprove, onReject)),
        DataCell(
          attendanceStatus == 'missing'
              ? const Text('—')
              : TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  static Widget _checkInCell(DateTime checkInTime) {
    return Text(
      '${checkInTime.day.toString().padLeft(2, '0')} '
      '${_month(checkInTime.month)} • '
      '${_formatTime(checkInTime)}',
      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
    );
  }

  static Widget _timingCell(String timingStatus) {
    final isLate = timingStatus == 'late';

    final color = isLate ? const Color(0xFFE53935) : const Color(0xFF35A853);

    final label = isLate ? 'Late' : 'On Time';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static Widget _statusCell(String status) {
    final normalizedStatus = status.toLowerCase();

    Color color;
    String label;

    switch (normalizedStatus) {
      case 'approved':
        color = const Color(0xFF35A853);
        label = 'Approved';
        break;

      case 'rejected':
        color = const Color(0xFFE53935);
        label = 'Rejected';
        break;

      default:
        color = const Color(0xFFF59E0B);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static String _roleLabel(String role) {
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

  static Widget _reviewCell(bool teamLeadReviewed, bool areaManagerReviewed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _review('TL', teamLeadReviewed),
        const SizedBox(width: 12),
        _review('AM', areaManagerReviewed),
      ],
    );
  }

  static Widget _review(String label, bool reviewed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF687385)),
        ),
        const SizedBox(width: 4),
        Icon(
          reviewed ? Icons.check_rounded : Icons.remove_rounded,
          size: 16,
          color: reviewed ? const Color(0xFF35A853) : const Color(0xFF98A1AD),
        ),
      ],
    );
  }

  static Widget _locationCell(
    BuildContext context,
    double? latitude,
    double? longitude,
  ) {
    final hasLocation = latitude != null && longitude != null;

    return TextButton(
      onPressed: hasLocation
          ? () async {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1'
                '&query=$latitude,$longitude',
              );

              try {
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );

                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to open location.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to open location.')),
                  );
                }
              }
            }
          : null,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 17,
            color: hasLocation
                ? const Color(0xFF155084)
                : const Color(0xFF98A1AD),
          ),
          const SizedBox(width: 5),
          Text(
            hasLocation ? 'View' : 'Unavailable',
            style: TextStyle(
              fontSize: 12,
              color: hasLocation
                  ? const Color(0xFF155084)
                  : const Color(0xFF98A1AD),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _approvalCell(
    String approvalStatus,
    VoidCallback onApprove,
    VoidCallback onReject,
  ) {
    final status = approvalStatus.toLowerCase();

    if (status == 'approved') {
      return _statusBadge(
        icon: Icons.check_rounded,
        text: 'Approved',
        color: const Color(0xFF35A853),
      );
    }

    if (status == 'rejected') {
      return _statusBadge(
        icon: Icons.close_rounded,
        text: 'Rejected',
        color: const Color(0xFFE53935),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          icon: Icons.close_rounded,
          color: const Color(0xFFE53935),
          onPressed: onReject,
        ),
        const SizedBox(width: 10),
        _actionButton(
          icon: Icons.check_rounded,
          color: const Color(0xFF35A853),
          onPressed: onApprove,
        ),
      ],
    );
  }

  static Widget _statusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.2),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  static String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
