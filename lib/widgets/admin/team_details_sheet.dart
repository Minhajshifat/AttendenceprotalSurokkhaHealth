import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/admin_service.dart';

class TeamDetailsSheet extends StatefulWidget {
  final String teamId;
  final String areaManagerId;

  const TeamDetailsSheet({
    super.key,
    required this.teamId,
    required this.areaManagerId,
  });

  @override
  State<TeamDetailsSheet> createState() => _TeamDetailsSheetState();
}

class _TeamDetailsSheetState extends State<TeamDetailsSheet> {
  final AdminService _adminService = AdminService();

  bool _isLoading = true;
  bool _isReviewingAll = false;

  String _teamName = '';

  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final members = await _adminService.getAreaManagerTeamAttendance(
        widget.teamId,
      );

      final teamName = await _adminService.getTeamName(widget.teamId.trim());

      debugPrint('TEAM ID: ${widget.teamId}');
      debugPrint('TEAM NAME: $teamName');

      if (!mounted) return;

      setState(() {
        _members = members;
        _teamName = teamName;
      });
    } catch (e, stackTrace) {
      debugPrint('TEAM DETAILS ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Unable to load team: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveMember(Map<String, dynamic> member) async {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    if (attendance == null) return;

    final uid = member['uid']?.toString();

    if (uid == null || uid.isEmpty) {
      _showMessage('Invalid employee information.');
      return;
    }

    final attendanceId = '${uid}_${_adminService.getTodayDateKey()}';

    try {
      await _adminService.approveByAreaManager(
        attendanceId: attendanceId,
        reviewedBy: widget.areaManagerId,
      );

      await _loadTeam();

      if (!mounted) return;

      _showMessage('${member['name'] ?? 'Employee'} attendance approved.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to approve attendance: $e');
    }
  }

  Future<void> _rejectMember(Map<String, dynamic> member) async {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    if (attendance == null) return;

    final uid = member['uid']?.toString();

    if (uid == null || uid.isEmpty) {
      _showMessage('Invalid employee information.');
      return;
    }

    final attendanceId = '${uid}_${_adminService.getTodayDateKey()}';

    try {
      await _adminService.rejectByAreaManager(
        attendanceId: attendanceId,
        reviewedBy: widget.areaManagerId,
      );

      await _loadTeam();

      if (!mounted) return;

      _showMessage('${member['name'] ?? 'Employee'} attendance rejected.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to reject attendance: $e');
    }
  }

  Future<void> _reviewAll() async {
    if (_isReviewingAll) return;

    final eligibleCount = _eligibleCount;

    if (eligibleCount == 0) {
      _showMessage('No attendance is ready for approval.');
      return;
    }

    final confirmed = await _confirmReviewAll(eligibleCount);

    if (!confirmed || !mounted) return;

    setState(() {
      _isReviewingAll = true;
    });

    try {
      final count = await _adminService.approveAllPendingByAreaManager(
        teamId: widget.teamId,
        reviewedBy: widget.areaManagerId,
      );

      await _loadTeam();

      if (!mounted) return;

      _showMessage(
        '$count attendance record${count == 1 ? '' : 's'} approved.',
      );
    } catch (e, stackTrace) {
      debugPrint('REVIEW ALL ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Unable to approve attendance: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isReviewingAll = false;
        });
      }
    }
  }

  Future<bool> _confirmReviewAll(int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Approve All Attendance',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Approve $count pending attendance '
            'record${count == 1 ? '' : 's'}?',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155084),
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve All'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  bool _canReview(Map<String, dynamic> member) {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    if (attendance == null) {
      return false;
    }

    final status =
        attendance['attendanceStatus']?.toString() ??
        attendance['status']?.toString() ??
        'pending';

    return status == 'pending';
  }

  int get _eligibleCount {
    return _members.where(_canReview).length;
  }

  Future<void> _viewLocation(Map<String, dynamic> attendance) async {
    final latitude = (attendance['latitude'] as num?)?.toDouble();

    final longitude = (attendance['longitude'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      _showMessage('Location data is not available.');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open Google Maps.');
      }
    } catch (e) {
      debugPrint('MAP ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to open Google Maps.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.92;

    return SafeArea(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F9FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadTeam,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                        children: [
                          _buildSummary(),
                          const SizedBox(height: 16),

                          if (_eligibleCount > 0) _buildReviewAll(),

                          if (_eligibleCount > 0) const SizedBox(height: 18),

                          _buildMembers(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teamName.isEmpty ? 'Loading Team...' : _teamName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Team Attendance',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final total = _members.length;

    final checkedIn = _members
        .where((member) => member['attendance'] != null)
        .length;

    final onTime = _members
        .where((member) => _timingStatus(member['attendance']) == 'on_time')
        .length;

    final late = _members
        .where((member) => _timingStatus(member['attendance']) == 'late')
        .length;

    final reviewed = _members
        .where((member) => _isAreaReviewed(member['attendance']))
        .length;

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
            "Today's Summary",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _summaryItem('People', '$total'),
              _summaryItem('Checked In', '$checkedIn'),
              _summaryItem('On Time', '$onTime'),
              _summaryItem('Late', '$late'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 17,
                color: Color(0xFF155084),
              ),
              const SizedBox(width: 7),
              Text(
                'Area Manager Reviewed',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
              ),
              const Spacer(),
              Text(
                '$reviewed / $total',
                style: GoogleFonts.poppins(
                  fontSize: 11,
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

  Widget _summaryItem(String label, String value) {
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

  Widget _buildReviewAll() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.done_all_rounded, color: Color(0xFF155084)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_eligibleCount attendance ready',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF172B4D),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isReviewingAll ? null : _reviewAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155084),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: _isReviewingAll
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Approve All'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembers() {
    if (_members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No members found in this team.')),
      );
    }

    final teamLeads = _members
        .where((member) => member['isTeamLead'] == true)
        .toList();

    final agents = _members
        .where((member) => member['isTeamLead'] != true)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (teamLeads.isNotEmpty) ...[
          Text(
            'Team Lead',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 12),
          ...teamLeads.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildMemberCard(member),
            ),
          ),
        ],
        if (agents.isNotEmpty) ...[
          Text(
            'Agents',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 12),
          ...agents.map(_buildMemberCard),
        ],
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    final attendanceStatus =
        attendance?['attendanceStatus']?.toString() ??
        attendance?['status']?.toString() ??
        'pending';

    final isTeamLead = member['isTeamLead'] == true;

    final areaReviewed = _isAreaReviewed(attendance);

    final teamLeadReviewed = isTeamLead
        ? true
        : attendance?['teamLeadReviewed'] == true;

    final canReview = _canReview(member);

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
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF5FA),
                child: Icon(
                  isTeamLead
                      ? Icons.supervisor_account_outlined
                      : Icons.person_outline,
                  color: const Color(0xFF155084),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name']?.toString() ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172B4D),
                      ),
                    ),
                    Text(
                      '${member['employeeId'] ?? '—'} • '
                      '${isTeamLead ? 'Team Lead' : 'Agent'}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(attendanceStatus),
            ],
          ),
          const SizedBox(height: 16),

          if (attendance == null)
            _missingAttendance()
          else ...[
            _infoRow(
              'Check-in',
              _formatTime(attendance['checkInTime']),
              Icons.access_time_rounded,
            ),
            const SizedBox(height: 9),

            _infoRow(
              'Timing',
              _timingLabel(attendance['timingStatus']?.toString()),
              Icons.schedule_outlined,
              valueColor: _timingColor(attendance['timingStatus']?.toString()),
            ),
            const SizedBox(height: 9),

            _infoRow(
              'Approval',
              _attendanceStatusLabel(attendanceStatus),
              Icons.assignment_turned_in_outlined,
              valueColor: _attendanceStatusColor(attendanceStatus),
            ),
            const SizedBox(height: 14),

            _reviewRow('Team Lead', teamLeadReviewed),

            const SizedBox(height: 7),

            _reviewRow('Area Manager', areaReviewed),

            const SizedBox(height: 12),

            if (canReview)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _approveMember(member);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43C047),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _rejectMember(member);
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 4),

            TextButton.icon(
              onPressed: () {
                _viewLocation(attendance);
              },
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text('View Location'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF155084),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _missingAttendance() {
    return Row(
      children: [
        const Icon(Icons.person_off_outlined, size: 19, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          'No attendance submitted',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valueColor ?? const Color(0xFF155084)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF172B4D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, bool reviewed) {
    return Row(
      children: [
        Icon(
          reviewed ? Icons.verified_outlined : Icons.pending_outlined,
          size: 17,
          color: reviewed ? const Color(0xFF43C047) : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
        ),
        const Spacer(),
        Text(
          reviewed ? 'Reviewed' : 'Not Reviewed',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: reviewed ? const Color(0xFF43C047) : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final label = _attendanceStatusLabel(status);

    final color = _attendanceStatusColor(status);

    final backgroundColor = _attendanceStatusBackgroundColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _attendanceStatusLabel(String? status) {
    switch (status) {
      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'pending':
      default:
        return 'Waiting for Approval';
    }
  }

  Color _attendanceStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF43C047);

      case 'rejected':
        return Colors.red;

      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Color _attendanceStatusBackgroundColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFFEAF7EB);

      case 'rejected':
        return const Color(0xFFFFEAEA);

      case 'pending':
      default:
        return const Color(0xFFFFF4E5);
    }
  }

  bool _isAreaReviewed(dynamic attendance) {
    if (attendance is! Map<String, dynamic>) {
      return false;
    }

    return attendance['areaManagerReviewed'] == true;
  }

  String? _timingStatus(dynamic attendance) {
    if (attendance is! Map<String, dynamic>) {
      return null;
    }

    return attendance['timingStatus']?.toString();
  }

  String _timingLabel(String? status) {
    switch (status) {
      case 'on_time':
        return 'On Time';

      case 'late':
        return 'Late';

      default:
        return '—';
    }
  }

  Color _timingColor(String? status) {
    switch (status) {
      case 'on_time':
        return const Color(0xFF43C047);

      case 'late':
        return Colors.red;

      default:
        return Colors.black54;
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) {
      return '—';
    }

    try {
      final dateTime = value.toDate();

      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;

      final minute = dateTime.minute.toString().padLeft(2, '0');

      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return 'Processing...';
    }
  }
}
