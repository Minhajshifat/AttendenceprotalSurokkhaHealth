import 'package:flutter/material.dart';

class TeamApprovalCard extends StatelessWidget {
  final String teamName;
  final String teamLeadName;
  final int pendingCount;
  final VoidCallback onTap;

  const TeamApprovalCard({
    super.key,
    required this.teamName,
    required this.teamLeadName,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E8EF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: Color(0xFF155084),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Team Lead: $teamLeadName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A8491),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pendingCount Pending',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE68A00),
                  ),
                ),
              ),

            const SizedBox(width: 10),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7A8491),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
