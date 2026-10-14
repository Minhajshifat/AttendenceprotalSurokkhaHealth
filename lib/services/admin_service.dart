import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================================================
  // DATE
  // ==================================================

  String _getDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String getTodayDateKey() {
    return _getDateKey(DateTime.now());
  }

  // ==================================================
  // GET TEAM NAME
  // ==================================================

  // ==================================================
  // GET ALL TEAM IDS
  // ==================================================

  Future<List<String>> getAllTeamIds() async {
    final snapshot = await _firestore.collection('users').get();

    final teams = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final teamId = data['teamId']?.toString().trim();

      if (teamId != null && teamId.isNotEmpty) {
        teams.add(teamId);
      }
    }

    final result = teams.toList()..sort();

    return result;
  }

  Future<String> getTeamName(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();

    if (doc.exists) {
      final data = doc.data();

      final name = data?['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      final teamName = data?['teamName']?.toString().trim();

      if (teamName != null && teamName.isNotEmpty) {
        return teamName;
      }
    }

    final usersSnapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .limit(1)
        .get();

    if (usersSnapshot.docs.isNotEmpty) {
      final data = usersSnapshot.docs.first.data();

      final name = data['teamName']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    return 'Unknown Team';
  }
  // ==================================================
  // GET TEAM MEMBERS
  // ==================================================

  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId) async {
    final cleanTeamId = teamId.trim();

    final snapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: cleanTeamId)
        .get();

    final members = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      members.add({
        'uid': doc.id,
        'name': data['name']?.toString() ?? '',
        'employeeId': data['employeeId']?.toString() ?? '',
        'email': data['email']?.toString() ?? '',
        'role': data['role']?.toString() ?? '',
        'teamId': data['teamId']?.toString() ?? '',
        'isActive': data['isActive'] ?? true,
      });
    }

    members.sort((a, b) {
      final aRole = a['role'].toString();

      final bRole = b['role'].toString();

      if (aRole == 'team_lead' && bRole != 'team_lead') {
        return -1;
      }

      if (aRole != 'team_lead' && bRole == 'team_lead') {
        return 1;
      }

      return a['name'].toString().toLowerCase().compareTo(
        b['name'].toString().toLowerCase(),
      );
    });

    return members;
  }

  // ==================================================
  // GET TEAM LEAD
  // ==================================================

  Future<Map<String, dynamic>?> getTeamLead(String teamId) async {
    final cleanTeamId = teamId.trim();

    final snapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: cleanTeamId)
        .where('role', isEqualTo: 'team_lead')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    final data = doc.data();

    return {
      'uid': doc.id,
      'name': data['name']?.toString() ?? '',
      'employeeId': data['employeeId']?.toString() ?? '',
      'email': data['email']?.toString() ?? '',
      'role': data['role']?.toString() ?? '',
      'teamId': data['teamId']?.toString() ?? '',
    };
  }

  // ==================================================
  // GET COMPLETE TEAM ATTENDANCE
  // ==================================================

  Future<List<Map<String, dynamic>>> getAreaManagerTeamAttendance(
    String teamId,
  ) async {
    final members = await getTeamMembers(teamId);

    final dateKey = getTodayDateKey();

    final result = <Map<String, dynamic>>[];

    for (final member in members) {
      final uid = member['uid'].toString();

      final attendanceDoc = await _firestore
          .collection('attendance')
          .doc('${uid}_$dateKey')
          .get();

      final attendance = attendanceDoc.exists ? attendanceDoc.data() : null;

      result.add({
        ...member,
        'isTeamLead': member['role'] == 'team_lead',
        'attendance': attendance,
      });
    }

    return result;
  }

  // ==================================================
  // TEAM SUMMARY
  // ==================================================
  Future<Map<String, dynamic>> getTeamSummary(String teamId) async {
    final members = await getAreaManagerTeamAttendance(teamId);

    final teamName = await getTeamName(teamId);

    int totalEmployees = 0;
    int checkedIn = 0;
    int missing = 0;
    int onTime = 0;
    int late = 0;
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    int areaManagerReviewed = 0;
    int areaManagerPending = 0;

    for (final member in members) {
      // Team Lead + all Agents = Total Members
      totalEmployees++;

      final attendance = member['attendance'] as Map<String, dynamic>?;

      // কেউ attendance না দিলে Missing
      // Team Lead হলেও Missing count হবে
      if (attendance == null) {
        missing++;
        continue;
      }

      // Attendance থাকলে Checked In
      checkedIn++;

      final timing = attendance['timingStatus']?.toString();

      final status =
          attendance['attendanceStatus']?.toString() ??
          attendance['status']?.toString();

      // On Time
      if (timing == 'on_time') {
        onTime++;
      }

      // Late
      if (timing == 'late') {
        late++;
      }

      // Pending Approval
      if (status == 'pending') {
        pending++;
      }

      // Approved
      if (status == 'approved') {
        approved++;
      }

      // Rejected
      if (status == 'rejected') {
        rejected++;
      }
    }

    final teamLead = await getTeamLead(teamId);

    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamLead': teamLead,
      'totalEmployees': totalEmployees,
      'checkedIn': checkedIn,
      'missing': missing,
      'onTime': onTime,
      'late': late,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
      'areaManagerReviewed': areaManagerReviewed,
      'areaManagerPending': areaManagerPending,
    };
  }
  // ==================================================
  // MULTIPLE TEAM SUMMARIES
  // ==================================================

  Future<List<Map<String, dynamic>>> getTeamSummaries(
    List<String> teamIds,
  ) async {
    final summaries = <Map<String, dynamic>>[];

    for (final teamId in teamIds) {
      final cleanTeamId = teamId.trim();

      if (cleanTeamId.isEmpty) {
        continue;
      }

      final summary = await getTeamSummary(cleanTeamId);

      summaries.add(summary);
    }

    return summaries;
  } // ==================================================
  // ALL TEAM SUMMARIES
  // ==================================================
  // ==================================================
  // GET ASSIGNED TEAM SUMMARIES
  // ==================================================

  Future<List<Map<String, dynamic>>> getAssignedTeamSummaries(
    List<String> teamIds,
  ) async {
    if (teamIds.isEmpty) {
      return [];
    }

    final summaries = <Map<String, dynamic>>[];

    for (final teamId in teamIds) {
      final cleanTeamId = teamId.trim();

      if (cleanTeamId.isEmpty) {
        continue;
      }

      final summary = await getTeamSummary(cleanTeamId);

      summaries.add(summary);
    }

    return summaries;
  }

  Future<List<Map<String, dynamic>>> getAllTeamSummaries() async {
    final teams = await getAllTeamIds();

    final summaries = <Map<String, dynamic>>[];

    for (final teamId in teams) {
      final summary = await getTeamSummary(teamId);

      summaries.add(summary);
    }

    return summaries;
  }

  // ==================================================
  // AREA MANAGER TEAM SUMMARIES
  // ==================================================

  Future<List<Map<String, dynamic>>> getAreaManagerTeamSummaries(
    List<String> teamIds,
  ) async {
    final cleanTeamIds = teamIds
        .map((teamId) => teamId.trim())
        .where((teamId) => teamId.isNotEmpty)
        .toSet()
        .toList();

    if (cleanTeamIds.isEmpty) {
      return [];
    }

    final summaries = <Map<String, dynamic>>[];

    for (final teamId in cleanTeamIds) {
      final summary = await getTeamSummary(teamId);

      summaries.add(summary);
    }

    return summaries;
  }
  // ==================================================
  // ORGANIZATION SUMMARY
  // ==================================================

  Future<Map<String, int>> getOrganizationSummary() async {
    final summaries = await getAllTeamSummaries();

    int total = 0;
    int checkedIn = 0;
    int missing = 0;
    int onTime = 0;
    int late = 0;
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    for (final summary in summaries) {
      total += summary['totalEmployees'] as int;
      checkedIn += summary['checkedIn'] as int;
      missing += summary['missing'] as int;
      onTime += summary['onTime'] as int;
      late += summary['late'] as int;
      pending += summary['pending'] as int;
      approved += summary['approved'] as int;
      rejected += summary['rejected'] as int;
    }

    return {
      'total': total,
      'checkedIn': checkedIn,
      'missing': missing,
      'onTime': onTime,
      'late': late,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  // ==================================================
  // APPROVE ALL PENDING ATTENDANCE
  // ==================================================

  Future<int> approveAllPendingByAreaManager({
    required String teamId,
    required String reviewedBy,
  }) async {
    final members = await getAreaManagerTeamAttendance(teamId);

    final batch = _firestore.batch();

    int approvedCount = 0;

    for (final member in members) {
      final attendance = member['attendance'] as Map<String, dynamic>?;

      if (attendance == null) {
        continue;
      }

      final status =
          attendance['attendanceStatus']?.toString() ??
          attendance['status']?.toString() ??
          'pending';

      if (status != 'pending') {
        continue;
      }

      final uid = member['uid'].toString();

      final attendanceId = '${uid}_${getTodayDateKey()}';

      final attendanceRef = _firestore
          .collection('attendance')
          .doc(attendanceId);

      batch.update(attendanceRef, {
        'attendanceStatus': 'approved',
        'areaManagerReviewed': true,
        'areaManagerReviewedBy': reviewedBy,
        'areaManagerReviewedAt': FieldValue.serverTimestamp(),
      });

      approvedCount++;
    }

    if (approvedCount > 0) {
      await batch.commit();
    }

    return approvedCount;
  }

  // ==================================================
  // APPROVE ATTENDANCE
  // ==================================================

  Future<void> approveByAreaManager({
    required String attendanceId,
    required String reviewedBy,
  }) async {
    final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

    final doc = await attendanceRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    await attendanceRef.update({
      'attendanceStatus': 'approved',
      'areaManagerReviewed': true,
      'areaManagerReviewedBy': reviewedBy,
      'areaManagerReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // REJECT ATTENDANCE
  // ==================================================

  Future<void> rejectByAreaManager({
    required String attendanceId,
    required String reviewedBy,
  }) async {
    final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

    final doc = await attendanceRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    await attendanceRef.update({
      'attendanceStatus': 'rejected',
      'areaManagerReviewed': true,
      'areaManagerReviewedBy': reviewedBy,
      'areaManagerReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getAreaAttendanceHistory({
    required List<String> teamIds,
    int days = 30,
  }) async {
    if (teamIds.isEmpty) {
      return [];
    }

    final now = DateTime.now();

    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final snapshot = await _firestore
        .collection('attendance')
        .where('teamId', whereIn: teamIds)
        .get();

    final history = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((attendance) {
          final checkInTime = attendance['checkInTime'];

          if (checkInTime is! Timestamp) {
            return false;
          }

          return !checkInTime.toDate().isBefore(startDate);
        })
        .toList();

    history.sort((a, b) {
      final aTime = (a['checkInTime'] as Timestamp).toDate();
      final bTime = (b['checkInTime'] as Timestamp).toDate();

      return bTime.compareTo(aTime);
    });

    return history;
  }
}
