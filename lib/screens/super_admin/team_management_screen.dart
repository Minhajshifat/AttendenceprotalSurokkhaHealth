import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_user.dart';
import '../../models/team_model.dart';
import '../../services/team_service.dart';
import '../../widgets/super_admin/assign_agents_dialog.dart';
import '../../widgets/super_admin/team_form_dialog.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final TeamService _teamService = TeamService();

  Future<void> _showAssignAgentsDialog(TeamModel team) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .get();

    final allAgents = snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();

    final availableAgents = allAgents.where((agent) {
      return agent.teamId.isEmpty || agent.teamId == team.id;
    }).toList();

    final selectedAgentIds = availableAgents
        .where((agent) => agent.teamId == team.id)
        .map((agent) => agent.uid)
        .toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AssignAgentsDialog(
          team: team,
          agents: availableAgents,
          selectedAgentIds: selectedAgentIds,
          onSave: (agentIds) async {
            await _teamService.assignAgentsToTeam(
              team: team,
              agentIds: agentIds,
            );
          },
        );
      },
    );
  }

  Future<void> _showTeamDialog({TeamModel? team}) async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    final teamsSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .get();

    final users = usersSnapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();

    final existingTeams = teamsSnapshot.docs
        .map((doc) => TeamModel.fromMap(doc.id, doc.data()))
        .toList();

    final areaManagers = users.where((user) => user.role == 'admin').toList();

    final assignedTeamLeadIds = existingTeams
        .where((existingTeam) {
          if (team == null) {
            return true;
          }

          return existingTeam.id != team.id;
        })
        .map((existingTeam) => existingTeam.teamLeadId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final teamLeads = users.where((user) {
      if (user.role != 'team_lead') {
        return false;
      }

      return !assignedTeamLeadIds.contains(user.uid);
    }).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return TeamFormDialog(
          team: team,
          areaManagers: areaManagers,
          teamLeads: teamLeads,
          onSave:
              ({
                required String name,
                required String areaManagerId,
                required String teamLeadId,
              }) async {
                if (team == null) {
                  await _teamService.createTeam(
                    name: name,
                    areaManagerId: areaManagerId,
                    teamLeadId: teamLeadId,
                  );
                } else {
                  final updatedTeam = TeamModel(
                    id: team.id,
                    name: name,
                    areaManagerId: areaManagerId,
                    teamLeadId: teamLeadId,
                    memberCount: team.memberCount,
                    isActive: team.isActive,
                  );

                  await _teamService.updateTeam(team: updatedTeam);
                }
              },
        );
      },
    );
  }

  Future<void> _deleteTeam(TeamModel team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Team',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete ${team.name}?',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _teamService.deleteTeam(teamId: team.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Team Management',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTeamDialog();
        },
        backgroundColor: const Color(0xFF155084),
        icon: const Icon(Icons.group_add_outlined),
        label: Text('Create Team', style: GoogleFonts.poppins(fontSize: 12)),
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: _teamService.getTeams(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load teams'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data!;

          if (teams.isEmpty) {
            return Center(
              child: Text(
                'No teams created yet',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF7A8491),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: teams.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final team = teams[index];

              return _TeamCard(
                team: team,
                onEdit: () {
                  _showTeamDialog(team: team);
                },
                onAssignAgents: () {
                  _showAssignAgentsDialog(team);
                },
                onDelete: () {
                  _deleteTeam(team);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssignAgents;

  const _TeamCard({
    required this.team,
    required this.onEdit,
    required this.onAssignAgents,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_outlined, color: Color(0xFF155084)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${team.memberCount} members',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF7A8491),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Assign Agents',
            onPressed: onAssignAgents,
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: Color(0xFF155084),
            ),
          ),
          IconButton(
            tooltip: 'Edit Team',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF155084)),
          ),
          IconButton(
            tooltip: 'Delete Team',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
