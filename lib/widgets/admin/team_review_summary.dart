import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamReviewSummary extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  const TeamReviewSummary({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    final total = members.length;

    final checkedIn = members
        .where((member) => member['attendance'] != null)
        .length;

    final onTime = members.where((member) {
      final attendance = member['attendance'] as Map<String, dynamic>?;

      return attendance?['timingStatus'] == 'on_time';
    }).length;

    final late = members.where((member) {
      final attendance = member['attendance'] as Map<String, dynamic>?;

      return attendance?['timingStatus'] == 'late';
    }).length;

    final reviewed = members.where((member) {
      final attendance = member['attendance'] as Map<String, dynamic>?;

      return attendance?['areaManagerReviewed'] == true;
    }).length;

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
          Text(
            'Today',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'People', value: '$total'),
              _Stat(label: 'Checked In', value: '$checkedIn'),
              _Stat(label: 'On Time', value: '$onTime'),
              _Stat(label: 'Late', value: '$late'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 18,
                color: Color(0xFF155084),
              ),
              const SizedBox(width: 8),
              Text(
                'Area Manager Review',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
              ),
              const Spacer(),
              Text(
                '$reviewed / $total',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF155084),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
