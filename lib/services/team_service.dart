import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/team_model.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teamsCollection =>
      _firestore.collection('teams');

  // ==================================================
  // CREATE TEAM
  // ==================================================

  Future<void> createTeam({
    required String name,
    required String areaManagerId,
    required String teamLeadId,
  }) async {
    final batch = _firestore.batch();

    final teamRef = _teamsCollection.doc();

    final team = TeamModel(
      id: teamRef.id,
      name: name.trim(),
      areaManagerId: areaManagerId,
      teamLeadId: teamLeadId,
      memberCount: 0,
      isActive: true,
    );

    // Create team
    batch.set(teamRef, team.toMap());

    // Add team ID to Area Manager's teamIds array
    final areaManagerRef = _firestore.collection('users').doc(areaManagerId);

    batch.update(areaManagerRef, {
      'teamIds': FieldValue.arrayUnion([teamRef.id]),
    });

    // Assign Team Lead
    final teamLeadRef = _firestore.collection('users').doc(teamLeadId);

    batch.update(teamLeadRef, {'teamId': teamRef.id, 'adminId': areaManagerId});

    await batch.commit();
  }

  // ==================================================
  // GET UNASSIGNED AGENTS
  // ==================================================

  Future<List<AppUser>> getUnassignedAgents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .where((agent) => agent.teamId.isEmpty)
        .toList();
  }

  // ==================================================
  // ASSIGN / UNASSIGN AGENTS
  // ==================================================

  Future<void> assignAgentsToTeam({
    required TeamModel team,
    required List<String> agentIds,
  }) async {
    final batch = _firestore.batch();

    final currentAgentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .where('teamId', isEqualTo: team.id)
        .get();

    final currentAgentIds = currentAgentsSnapshot.docs
        .map((doc) => doc.id)
        .toSet();

    final newAgentIds = agentIds.toSet();

    final removedAgentIds = currentAgentIds.difference(newAgentIds);

    for (final agentId in removedAgentIds) {
      final agentRef = _firestore.collection('users').doc(agentId);

      batch.update(agentRef, {'teamId': '', 'teamLeadId': '', 'adminId': ''});
    }

    for (final agentId in newAgentIds) {
      final agentRef = _firestore.collection('users').doc(agentId);

      batch.update(agentRef, {
        'teamId': team.id,
        'teamLeadId': team.teamLeadId,
        'adminId': team.areaManagerId,
      });
    }

    batch.update(_teamsCollection.doc(team.id), {
      'memberCount': newAgentIds.length,
    });

    await batch.commit();
  }

  // ==================================================
  // UPDATE TEAM
  // ==================================================

  Future<void> updateTeam({required TeamModel team}) async {
    final oldTeamDoc = await _teamsCollection.doc(team.id).get();

    if (!oldTeamDoc.exists) {
      throw Exception('Team not found');
    }

    final oldTeam = TeamModel.fromMap(oldTeamDoc.id, oldTeamDoc.data()!);

    final batch = _firestore.batch();

    // Update team document
    batch.update(_teamsCollection.doc(team.id), team.toMap());

    // ==================================================
    // IF AREA MANAGER CHANGED
    // ==================================================

    if (oldTeam.areaManagerId != team.areaManagerId) {
      // Remove team from old Area Manager
      if (oldTeam.areaManagerId.isNotEmpty) {
        final oldAreaManagerRef = _firestore
            .collection('users')
            .doc(oldTeam.areaManagerId);

        batch.update(oldAreaManagerRef, {
          'teamIds': FieldValue.arrayRemove([team.id]),
        });
      }

      // Add team to new Area Manager
      if (team.areaManagerId.isNotEmpty) {
        final newAreaManagerRef = _firestore
            .collection('users')
            .doc(team.areaManagerId);

        batch.update(newAreaManagerRef, {
          'teamIds': FieldValue.arrayUnion([team.id]),
        });
      }
    }

    // ==================================================
    // IF TEAM LEAD CHANGED
    // ==================================================

    if (oldTeam.teamLeadId != team.teamLeadId) {
      if (oldTeam.teamLeadId.isNotEmpty) {
        final oldTeamLeadRef = _firestore
            .collection('users')
            .doc(oldTeam.teamLeadId);

        batch.update(oldTeamLeadRef, {'teamId': '', 'adminId': ''});
      }

      final newTeamLeadRef = _firestore
          .collection('users')
          .doc(team.teamLeadId);

      batch.update(newTeamLeadRef, {
        'teamId': team.id,
        'adminId': team.areaManagerId,
      });
    }

    // ==================================================
    // UPDATE CURRENT TEAM LEAD
    // ==================================================

    final currentTeamLeadRef = _firestore
        .collection('users')
        .doc(team.teamLeadId);

    batch.update(currentTeamLeadRef, {
      'teamId': team.id,
      'adminId': team.areaManagerId,
    });

    // ==================================================
    // UPDATE ALL ASSIGNED AGENTS
    // ==================================================

    final agentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .where('teamId', isEqualTo: team.id)
        .get();

    for (final agentDoc in agentsSnapshot.docs) {
      batch.update(agentDoc.reference, {
        'teamLeadId': team.teamLeadId,
        'adminId': team.areaManagerId,
      });
    }

    await batch.commit();
  }

  // ==================================================
  // DELETE TEAM
  // ==================================================

  Future<void> deleteTeam({required String teamId}) async {
    final teamDoc = await _teamsCollection.doc(teamId).get();

    if (!teamDoc.exists) {
      throw Exception('Team not found');
    }

    final team = TeamModel.fromMap(teamDoc.id, teamDoc.data()!);

    final batch = _firestore.batch();

    // Remove team ID from Area Manager
    if (team.areaManagerId.isNotEmpty) {
      final areaManagerRef = _firestore
          .collection('users')
          .doc(team.areaManagerId);

      batch.update(areaManagerRef, {
        'teamIds': FieldValue.arrayRemove([teamId]),
      });
    }

    // Get all assigned users
    final assignedUsersSnapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .get();

    // Remove team assignment from users
    for (final userDoc in assignedUsersSnapshot.docs) {
      batch.update(userDoc.reference, {
        'teamId': '',
        'teamLeadId': '',
        'adminId': '',
      });
    }

    // Delete team
    batch.delete(_teamsCollection.doc(teamId));

    await batch.commit();
  }

  // ==================================================
  // GET ALL TEAMS
  // ==================================================

  Stream<List<TeamModel>> getTeams() {
    return _teamsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // ==================================================
  // GET AREA MANAGERS
  // ==================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getAreaManagers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .snapshots();
  }

  // ==================================================
  // GET TEAM LEADS
  // ==================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getTeamLeads() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'team_lead')
        .snapshots();
  }
}
