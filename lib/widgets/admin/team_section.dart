import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'team_card.dart';

class TeamsSection extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final ValueChanged<String> onViewTeam;

  const TeamsSection({
    super.key,
    required this.teams,
    required this.onViewTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Teams',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF172B4D),
              ),
            ),
            const Spacer(),
            Text(
              '${teams.length} Teams',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (teams.isEmpty) _buildEmptyTeams(),

        ...teams.map((team) {
          final teamId = team['teamId']?.toString() ?? '';

          final teamName = team['teamName']?.toString() ?? 'Unknown Team';

          final teamLead = team['teamLead'] as Map<String, dynamic>?;

          return TeamCard(
            teamId: teamName,

            teamLeadName: teamLead?['name']?.toString() ?? 'Not assigned',

            totalEmployees: team['totalEmployees'] as int? ?? 0,

            checkedIn: team['checkedIn'] as int? ?? 0,

            missing: team['missing'] as int? ?? 0,

            onTime: team['onTime'] as int? ?? 0,

            late: team['late'] as int? ?? 0,

            // ACTUAL ATTENDANCE STATUS
            approved: team['approved'] as int? ?? 0,

            pending: team['pending'] as int? ?? 0,

            rejected: team['rejected'] as int? ?? 0,

            onViewTeam: () {
              onViewTeam(teamId);
            },
          );
        }),
      ],
    );
  }

  Widget _buildEmptyTeams() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text('No teams found.')),
    );
  }
}
