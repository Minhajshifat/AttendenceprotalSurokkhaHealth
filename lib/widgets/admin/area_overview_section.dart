import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'summary_card.dart';

class AreaOverviewSection extends StatelessWidget {
  final Map<String, int> summary;

  const AreaOverviewSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Area Overview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            SummaryCard(
              title: 'Employees',
              value: '${summary['total'] ?? 0}',
              icon: Icons.groups_outlined,
            ),
            SummaryCard(
              title: 'Checked In',
              value: '${summary['checkedIn'] ?? 0}',
              icon: Icons.how_to_reg_outlined,
            ),
            SummaryCard(
              title: 'Missing',
              value: '${summary['missing'] ?? 0}',
              icon: Icons.person_off_outlined,
            ),
            SummaryCard(
              title: 'On Time',
              value: '${summary['onTime'] ?? 0}',
              icon: Icons.check_circle_outline,
            ),
            SummaryCard(
              title: 'Late',
              value: '${summary['late'] ?? 0}',
              icon: Icons.schedule_outlined,
            ),
            SummaryCard(
              title: 'Pending',
              value: '${summary['pending'] ?? 0}',
              icon: Icons.pending_actions_outlined,
            ),
          ],
        ),
      ],
    );
  }
}
