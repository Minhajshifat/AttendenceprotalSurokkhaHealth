import 'package:flutter/material.dart';

class AreaManagerApprovalCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const AreaManagerApprovalCard({
    super.key,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
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
                Icons.manage_accounts_outlined,
                color: Color(0xFF155084),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Area Manager Attendance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review and approve area manager attendance',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7A8491)),
                  ),
                ],
              ),
            ),
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
