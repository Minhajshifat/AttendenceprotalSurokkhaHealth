import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamCard extends StatelessWidget {
  final String teamId;
  final String teamLeadName;
  final int rejected;
  // Total agents/employees + team lead
  final int totalEmployees;

  final int checkedIn;
  final int missing;
  final int onTime;
  final int late;

  final int approved;
  final int pending;

  final VoidCallback onViewTeam;

  const TeamCard({
    super.key,
    required this.teamId,
    required this.teamLeadName,
    required this.totalEmployees,
    required this.checkedIn,
    required this.missing,
    required this.rejected,
    required this.onTime,
    required this.late,
    required this.approved,
    required this.pending,
    required this.onViewTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // TEAM NAME + TOTAL MEMBERS
          // ==========================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  teamId,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF172B4D),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                '$totalEmployees Employees',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==========================================
          // TEAM LEAD
          // ==========================================
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 17,
                color: Color(0xFF155084),
              ),

              const SizedBox(width: 7),

              Flexible(
                child: Text(
                  'Team Lead: $teamLeadName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ==========================================
          // ATTENDANCE STATS
          // ==========================================
          Row(
            children: [
              Expanded(
                child: _SmallStat(label: 'Checked In', value: '$checkedIn'),
              ),

              Expanded(
                child: _SmallStat(label: 'Missing', value: '$missing'),
              ),

              Expanded(
                child: _SmallStat(label: 'On Time', value: '$onTime'),
              ),

              Expanded(
                child: _SmallStat(label: 'Late', value: '$late'),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ==========================================
          // APPROVAL STATUS
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  size: 17,
                  color: Color(0xFF155084),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Approval Status',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ),

                Text(
                  '$approved Approved',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF43C047),
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  '• $pending Pending',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ==========================================
          // VIEW TEAM
          // ==========================================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewTeam,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View Team'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF155084),
                side: const BorderSide(color: Color(0xFF155084)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;

  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
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
    );
  }
}
