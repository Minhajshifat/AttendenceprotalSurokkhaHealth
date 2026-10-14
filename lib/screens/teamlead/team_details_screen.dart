import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../widgets/admin/review_all_button.dart';
import '../../widgets/admin/team_details_header.dart';
import '../../widgets/admin/team_member_attendance_card.dart';
import '../../widgets/admin/team_review_summary.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;
  final String areaManagerId;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
    required this.areaManagerId,
  });

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
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
      final results = await Future.wait([
        _adminService.getAreaManagerTeamAttendance(widget.teamId),
        _adminService.getTeamName(widget.teamId),
      ]);

      final members = results[0] as List<Map<String, dynamic>>;

      final teamName = results[1] as String;

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

  Future<void> _reviewMember(Map<String, dynamic> member) async {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    if (attendance == null) {
      return;
    }

    if (!_isEligibleForReview(member)) {
      _showMessage('This attendance is not ready for Area Manager review.');
      return;
    }

    final uid = member['uid'].toString();

    try {
      setState(() {});

      final attendanceId = '${uid}_${_adminService.getTodayDateKey()}';

      await _adminService.approveByAreaManager(
        attendanceId: attendanceId,
        reviewedBy: widget.areaManagerId,
      );

      await _loadTeam();

      if (!mounted) return;

      _showMessage('${member['name']} attendance reviewed.');
    } catch (e, stackTrace) {
      debugPrint('AREA MANAGER REVIEW ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Unable to review attendance: $e');
    }
  }

  // ==================================================
  // REVIEW ALL
  // ==================================================

  Future<void> _reviewAll() async {
    if (_isReviewingAll) {
      return;
    }

    final count = _eligibleForReviewCount;

    if (count == 0) {
      _showMessage('No attendance is ready for review.');
      return;
    }

    final confirmed = await _confirmReviewAll(count);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isReviewingAll = true;
    });

    try {
      final reviewedCount = await _adminService.approveAllPendingByAreaManager(
        teamId: widget.teamId,
        reviewedBy: widget.areaManagerId,
      );

      await _loadTeam();

      if (!mounted) return;

      _showMessage(
        '$reviewedCount attendance record${reviewedCount == 1 ? '' : 's'} reviewed.',
      );
    } catch (e, stackTrace) {
      debugPrint('REVIEW ALL ERROR: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Unable to review attendance: $e');
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Review All'),
          content: Text('Review $count eligible attendance records?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Review All'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ==================================================
  // ELIGIBILITY
  // ==================================================

  bool _isEligibleForReview(Map<String, dynamic> member) {
    final attendance = member['attendance'] as Map<String, dynamic>?;

    if (attendance == null) {
      return false;
    }

    if (attendance['areaManagerReviewed'] == true) {
      return false;
    }

    final isTeamLead = member['isTeamLead'] == true;

    if (isTeamLead) {
      return true;
    }

    return attendance['teamLeadReviewed'] == true;
  }

  int get _eligibleForReviewCount {
    return _members.where(_isEligibleForReview).length;
  }

  // ==================================================
  // HELPERS
  // ==================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _teamName,
          style: const TextStyle(
            color: Color(0xFF155084),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF155084)),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadTeam,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeam,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  TeamDetailsHeader(teamId: _teamName, members: _members),

                  const SizedBox(height: 16),

                  TeamReviewSummary(members: _members),

                  const SizedBox(height: 16),

                  if (_eligibleForReviewCount > 0)
                    ReviewAllButton(
                      count: _eligibleForReviewCount,
                      isLoading: _isReviewingAll,
                      onPressed: _reviewAll,
                    ),

                  if (_eligibleForReviewCount > 0) const SizedBox(height: 20),

                  ..._members.map((member) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TeamMemberAttendanceCard(
                        member: member,
                        isUpdating: false,
                        canReview: _isEligibleForReview(member),
                        onReview: () {
                          _reviewMember(member);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
