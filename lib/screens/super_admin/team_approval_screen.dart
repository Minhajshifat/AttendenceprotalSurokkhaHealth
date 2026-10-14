import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/super_admin_service.dart';
import '../../widgets/super_admin/team_approval_card.dart';
import 'team_attendance_screen.dart';

class TeamApprovalScreen extends StatefulWidget {
  final AppUser user;

  const TeamApprovalScreen({super.key, required this.user});

  @override
  State<TeamApprovalScreen> createState() => _TeamApprovalScreenState();
}

class _TeamApprovalScreenState extends State<TeamApprovalScreen> {
  final SuperAdminService _service = SuperAdminService();

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _service.getAllTeamSummaries();

      if (!mounted) return;

      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('TEAM LIST ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load teams: $e')));
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTeams {
    if (_searchText.isEmpty) {
      return _teams;
    }

    return _teams.where((team) {
      final teamName = team['teamName'].toString().toLowerCase();

      final teamId = team['teamId'].toString().toLowerCase();

      return teamName.contains(_searchText) || teamId.contains(_searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance Approval',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTeams,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Team Attendance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Review attendance by team.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A8491)),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 28),

              const Text(
                'Teams',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 12),

              _searchField(),

              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredTeams.isEmpty)
                _emptyState()
              else
                ..._filteredTeams.map((team) {
                  final teamLead = team['teamLead'] as Map<String, dynamic>?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TeamApprovalCard(
                      teamName: team['teamName'].toString(),
                      teamLeadName:
                          teamLead?['name']?.toString() ?? 'Not assigned',
                      pendingCount: team['pending'] as int? ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamAttendanceScreen(
                              user: widget.user,
                              teamId: team['teamId'].toString(),
                              teamName: team['teamName'].toString(),
                              teamLeadName:
                                  teamLead?['name']?.toString() ??
                                  'Not assigned',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search team or team ID...',
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.close_rounded, size: 19),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF155084)),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, size: 40, color: Color(0xFF98A1AD)),
          SizedBox(height: 12),
          Text(
            'No teams found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }
}
