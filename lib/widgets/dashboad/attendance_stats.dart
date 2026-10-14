import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceStats extends StatelessWidget {
  final int total;
  final int checkedIn;
  final int missing;
  final int onTime;
  final int late;
  final int pending;
  final int approved;
  final int rejected;

  const AttendanceStats({
    super.key,
    required this.total,
    required this.checkedIn,
    required this.missing,
    required this.onTime,
    required this.late,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        title: 'Total',
        value: total,
        icon: Icons.groups_outlined,
        color: const Color(0xFF155084),
      ),
      _StatItem(
        title: 'Checked In',
        value: checkedIn,
        icon: Icons.login_rounded,
        color: const Color(0xFF155084),
      ),
      _StatItem(
        title: 'Missing',
        value: missing,
        icon: Icons.person_off_outlined,
        color: Colors.grey,
      ),
      _StatItem(
        title: 'On Time',
        value: onTime,
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF43C047),
      ),
      _StatItem(
        title: 'Late',
        value: late,
        icon: Icons.schedule_rounded,
        color: Colors.red,
      ),
      _StatItem(
        title: 'Pending',
        value: pending,
        icon: Icons.hourglass_empty_rounded,
        color: Colors.orange,
      ),
      _StatItem(
        title: 'Approved',
        value: approved,
        icon: Icons.verified_outlined,
        color: const Color(0xFF43C047),
      ),
      _StatItem(
        title: 'Rejected',
        value: rejected,
        icon: Icons.cancel_outlined,
        color: Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 500
            ? 2
            : constraints.maxWidth < 900
            ? 3
            : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) {
            return _buildStatCard(stats[index]);
          },
        );
      },
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stat.value}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172B4D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
