import 'package:flutter/material.dart';

class ApprovalTeamSection extends StatelessWidget {
  final String teamName;
  final String teamLeadName;
  final int pendingCount;
  final VoidCallback onApproveAll;

  const ApprovalTeamSection({
    super.key,
    required this.teamName,
    required this.teamLeadName,
    required this.pendingCount,
    required this.onApproveAll,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: isSmall ? _buildSmallLayout() : _buildDesktopLayout(),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _teamIcon(),
        const SizedBox(width: 14),
        Expanded(child: _teamInfo()),
        const SizedBox(width: 16),
        _pendingBadge(),
        const SizedBox(width: 18),
        _approveButton(),
      ],
    );
  }

  Widget _buildSmallLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _teamIcon(),
            const SizedBox(width: 12),
            Expanded(child: _teamInfo()),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [_pendingBadge(), _approveButton()],
        ),
      ],
    );
  }

  Widget _teamIcon() {
    return Container(
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
    );
  }

  Widget _teamInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF172B4D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Team Lead: $teamLeadName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7A8491)),
        ),
      ],
    );
  }

  Widget _pendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
    );
  }

  Widget _approveButton() {
    return ElevatedButton.icon(
      onPressed: onApproveAll,
      icon: const Icon(Icons.check_rounded, size: 17),
      label: const Text('Approve All Team'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF155084),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}
