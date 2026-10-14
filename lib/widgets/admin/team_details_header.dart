import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamDetailsHeader extends StatelessWidget {
  final String teamId;
  final List<Map<String, dynamic>> members;

  const TeamDetailsHeader({
    super.key,
    required this.teamId,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final teamLead = members.where((member) {
      final role = member['role']?.toString().trim().toLowerCase();

      return role == 'team_lead';
    });

    final teamLeadName = teamLead.isEmpty
        ? 'Not assigned'
        : teamLead.first['name']?.toString().trim().isNotEmpty == true
        ? teamLead.first['name'].toString()
        : 'Not assigned';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamId,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 18,
                color: Color(0xFF155084),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Team Lead: $teamLeadName',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
