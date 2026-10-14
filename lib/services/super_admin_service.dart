import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================================================
  // DASHBOARD STATISTICS
  // ==================================================

  Future<Map<String, int>> getDashboardStats() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final pendingApprovals = await getPendingApprovalCount();
    final teamsSnapshot = await _firestore.collection('teams').get();

    int agents = 0;
    int teamLeads = 0;
    int areaManagers = 0;
    int teams = 0;

    for (final document in usersSnapshot.docs) {
      final data = document.data();

      final role = data['role']?.toString() ?? '';

      final isActive = data['isActive'] ?? true;

      if (isActive != true) {
        continue;
      }

      switch (role) {
        case 'agent':
          agents++;
          break;

        case 'team_lead':
          teamLeads++;
          break;

        case 'admin':
          areaManagers++;
          break;
      }
    }

    for (final document in teamsSnapshot.docs) {
      final data = document.data();

      final isActive = data['isActive'] ?? true;

      if (isActive == true) {
        teams++;
      }
    }

    return {
      'agents': agents,
      'teamLeads': teamLeads,
      'areaManagers': areaManagers,
      'teams': teams,
      'pendingApprovals': pendingApprovals,
    };
  }
  // ==================================================
  // TODAY'S PENDING APPROVAL COUNT
  // ==================================================

  Future<int> getPendingApprovalCount() async {
    final today = getTodayDateKey();

    final snapshot = await _firestore
        .collection('attendance')
        .where('date', isEqualTo: today)
        .where('attendanceStatus', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }
  // ==================================================
  // ALL PENDING ATTENDANCE
  // ==================================================

  Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    final snapshot = await _firestore.collection('attendance').get();

    final List<Map<String, dynamic>> records = [];

    for (final document in snapshot.docs) {
      final data = document.data();

      final status = data['attendanceStatus']?.toString() ?? 'pending';

      if (status != 'pending') {
        continue;
      }

      final record = Map<String, dynamic>.from(data);

      record['attendanceId'] = document.id;

      records.add(record);
    }

    records.sort((a, b) {
      final aTime = _getTimestamp(a['checkInTime']);

      final bTime = _getTimestamp(b['checkInTime']);

      return bTime.compareTo(aTime);
    });

    return records;
  }

  // ==================================================
  // APPROVE INDIVIDUAL ATTENDANCE
  // ==================================================

  Future<void> approveAttendance({
    required String attendanceId,
    required String approvedBy,
  }) async {
    await _firestore.collection('attendance').doc(attendanceId).update({
      'attendanceStatus': 'approved',
      'approvalStatus': 'approved',
      'superAdminApproved': true,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectedBy': FieldValue.delete(),
      'rejectedAt': FieldValue.delete(),
      'rejectionReason': FieldValue.delete(),
    });
  }

  // ==================================================
  // REJECT INDIVIDUAL ATTENDANCE
  // ==================================================

  Future<void> rejectAttendance({
    required String attendanceId,
    required String rejectedBy,
    required String reason,
  }) async {
    await _firestore.collection('attendance').doc(attendanceId).update({
      'attendanceStatus': 'rejected',
      'approvalStatus': 'rejected',
      'superAdminApproved': false,
      'rejectedBy': rejectedBy,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
      'approvedBy': FieldValue.delete(),
      'approvedAt': FieldValue.delete(),
    });
  }

  // ==================================================
  // APPROVE ALL ATTENDANCE FOR A TEAM
  // ==================================================

  Future<int> approveAllTeamAttendance({
    required String teamId,
    required String approvedBy,
  }) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('teamId', isEqualTo: teamId)
        .get();

    final batch = _firestore.batch();

    int count = 0;

    for (final document in snapshot.docs) {
      final data = document.data();

      final status = data['attendanceStatus']?.toString() ?? 'pending';

      if (status != 'pending') {
        continue;
      }

      batch.update(document.reference, {
        'attendanceStatus': 'approved',
        'approvalStatus': 'approved',
        'superAdminApproved': true,
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectedBy': FieldValue.delete(),
        'rejectedAt': FieldValue.delete(),
        'rejectionReason': FieldValue.delete(),
      });

      count++;
    }

    if (count > 0) {
      await batch.commit();
    }

    return count;
  }

  // ==================================================
  // APPROVE ALL PENDING ATTENDANCE
  // ==================================================

  Future<int> approveAllPendingAttendance({required String approvedBy}) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('attendanceStatus', isEqualTo: 'pending')
        .get();

    const batchSize = 400;

    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = _firestore.batch();

      final end = (i + batchSize > snapshot.docs.length)
          ? snapshot.docs.length
          : i + batchSize;

      for (final doc in snapshot.docs.sublist(i, end)) {
        batch.update(doc.reference, {
          'attendanceStatus': 'approved',
          'approvalStatus': 'approved',
          'superAdminApproved': true,
          'approvedBy': approvedBy,
          'approvedAt': FieldValue.serverTimestamp(),
          'rejectedBy': FieldValue.delete(),
          'rejectedAt': FieldValue.delete(),
          'rejectionReason': FieldValue.delete(),
        });
      }

      await batch.commit();
    }

    return snapshot.docs.length;
  }

  Future<List<Map<String, dynamic>>> getAllTeamSummaries() async {
    final today = getTodayDateKey();

    // Run all Firestore queries in parallel
    final results = await Future.wait([
      _firestore.collection('teams').get(),

      _firestore.collection('users').where('isActive', isEqualTo: true).get(),

      _firestore.collection('attendance').where('date', isEqualTo: today).get(),
    ]);

    final teamsSnapshot = results[0];

    final usersSnapshot = results[1];

    final attendanceSnapshot = results[2];

    // ==================================================
    // CREATE ATTENDANCE LOOKUP MAP
    // userId -> attendance
    // ==================================================

    final attendanceByUser = <String, Map<String, dynamic>>{};

    for (final doc in attendanceSnapshot.docs) {
      final data = doc.data();

      final userId = data['userId']?.toString().trim();

      if (userId != null && userId.isNotEmpty) {
        attendanceByUser[userId] = {...data, 'attendanceId': doc.id};
      }
    }

    // ==================================================
    // GROUP ACTIVE USERS BY TEAM
    // ==================================================

    final membersByTeam = <String, List<Map<String, dynamic>>>{};

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();

      final role = data['role']?.toString().toLowerCase().trim() ?? '';

      final teamId = data['teamId']?.toString().trim() ?? '';

      // Super admin should not be included
      if (role == 'super_admin' || teamId.isEmpty) {
        continue;
      }

      membersByTeam.putIfAbsent(teamId, () => []);

      membersByTeam[teamId]!.add({
        'uid': userDoc.id,
        'name': data['name']?.toString() ?? '',
        'employeeId': data['employeeId']?.toString() ?? '',
        'role': role,
      });
    }

    // ==================================================
    // BUILD TEAM SUMMARIES
    // ==================================================

    final result = <Map<String, dynamic>>[];

    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();

      final isTeamActive = teamData['isActive'] ?? true;

      if (isTeamActive != true) {
        continue;
      }

      final teamId = teamDoc.id;

      final members = membersByTeam[teamId] ?? [];

      // Find Team Lead safely
      Map<String, dynamic> teamLead = {};

      for (final member in members) {
        if (member['role'] == 'team_lead') {
          teamLead = member;
          break;
        }
      }

      int agents = 0;
      int checkedIn = 0;
      int missing = 0;
      int onTime = 0;
      int late = 0;
      int pending = 0;
      int approved = 0;
      int rejected = 0;

      // ==================================================
      // CALCULATE ATTENDANCE
      // ==================================================

      for (final member in members) {
        final role = member['role']?.toString() ?? '';

        if (role == 'agent') {
          agents++;
        }

        final userId = member['uid'].toString();

        final attendance = attendanceByUser[userId];

        // No attendance record
        if (attendance == null) {
          if (role == 'agent') {
            missing++;
          }

          continue;
        }

        checkedIn++;

        final timingStatus = attendance['timingStatus']?.toString() ?? '';

        final attendanceStatus =
            attendance['attendanceStatus']?.toString() ??
            attendance['approvalStatus']?.toString() ??
            'pending';

        if (timingStatus == 'on_time') {
          onTime++;
        } else if (timingStatus == 'late') {
          late++;
        }

        if (attendanceStatus == 'pending') {
          pending++;
        } else if (attendanceStatus == 'approved') {
          approved++;
        } else if (attendanceStatus == 'rejected') {
          rejected++;
        }
      }

      result.add({
        'teamId': teamId,

        'teamName': teamData['name']?.toString() ?? 'Unnamed Team',

        'teamLead': teamLead,

        'totalMembers': agents,
        'agents': agents,

        'checkedIn': checkedIn,

        'missing': missing,

        'onTime': onTime,

        'late': late,

        'pending': pending,

        'approved': approved,

        'rejected': rejected,
      });
    }

    // ==================================================
    // SORT TEAMS BY NAME
    // ==================================================

    result.sort((a, b) {
      final aName = a['teamName']?.toString().toLowerCase() ?? '';

      final bName = b['teamName']?.toString().toLowerCase() ?? '';

      return aName.compareTo(bName);
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getTeamAttendance({
    required String teamId,
  }) async {
    final today = getTodayDateKey();

    final usersSnapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('isActive', isEqualTo: true)
        .get();

    final records = <Map<String, dynamic>>[];

    for (final userDocument in usersSnapshot.docs) {
      final userData = userDocument.data();
      final uid = userDocument.id;

      final attendanceId = '${uid}_$today';

      final attendanceDocument = await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .get();

      if (!attendanceDocument.exists) {
        continue;
      }

      final attendance = Map<String, dynamic>.from(attendanceDocument.data()!);

      attendance['attendanceId'] = attendanceDocument.id;

      attendance['name'] = userData['name']?.toString() ?? '';

      attendance['employeeId'] = userData['employeeId']?.toString() ?? '';

      attendance['role'] = userData['role']?.toString() ?? '';

      attendance['teamId'] = teamId;

      final checkInTime = attendance['checkInTime'];

      if (checkInTime is Timestamp) {
        attendance['checkInTime'] = checkInTime.toDate();
      }

      records.add(attendance);
    }

    records.sort((a, b) {
      final aTime = _getTimestamp(a['checkInTime']);

      final bTime = _getTimestamp(b['checkInTime']);

      return bTime.compareTo(aTime);
    });

    return records;
  }
  // ==================================================
  // GET TODAY OFFICE EMPLOYEE ATTENDANCE
  // ==================================================

  Future<List<Map<String, dynamic>>> getOfficeEmployeeAttendance() async {
    final today = getTodayDateKey();

    // Get active office employees
    final usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'office_employee')
        .where('isActive', isEqualTo: true)
        .get();

    final records = <Map<String, dynamic>>[];

    for (final userDocument in usersSnapshot.docs) {
      final userData = userDocument.data();
      final uid = userDocument.id;

      final attendanceId = '${uid}_$today';

      final attendanceDocument = await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .get();

      // Employee has not checked in today
      if (!attendanceDocument.exists) {
        records.add({
          'attendanceId': attendanceId,
          'userId': uid,
          'name': userData['name']?.toString() ?? '',
          'employeeId': userData['employeeId']?.toString() ?? '',
          'role': 'office_employee',
          'designation': userData['designation']?.toString() ?? '',
          'date': today,
          'attendanceStatus': 'missing',
          'timingStatus': '',
          'checkInTime': null,
          'latitude': null,
          'longitude': null,
        });

        continue;
      }

      final attendance = Map<String, dynamic>.from(attendanceDocument.data()!);

      attendance['attendanceId'] = attendanceDocument.id;
      attendance['userId'] = uid;

      attendance['name'] = userData['name']?.toString() ?? '';
      attendance['employeeId'] = userData['employeeId']?.toString() ?? '';
      attendance['role'] = 'office_employee';
      attendance['designation'] = userData['designation']?.toString() ?? '';

      final checkInTime = attendance['checkInTime'];

      if (checkInTime is Timestamp) {
        attendance['checkInTime'] = checkInTime.toDate();
      }

      records.add(attendance);
    }

    // Checked-in employees first, then missing employees.
    records.sort((a, b) {
      final aStatus = a['attendanceStatus']?.toString() ?? '';
      final bStatus = b['attendanceStatus']?.toString() ?? '';

      if (aStatus == 'missing' && bStatus != 'missing') {
        return 1;
      }

      if (aStatus != 'missing' && bStatus == 'missing') {
        return -1;
      }

      return (a['name']?.toString() ?? '').toLowerCase().compareTo(
        (b['name']?.toString() ?? '').toLowerCase(),
      );
    });

    return records;
  }
  // ==================================================
  // GET TODAY AREA MANAGER ATTENDANCE
  // ==================================================

  Future<List<Map<String, dynamic>>> getAreaManagerAttendance() async {
    final today = getTodayDateKey();

    final usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .where('isActive', isEqualTo: true)
        .get();

    final records = <Map<String, dynamic>>[];

    for (final userDocument in usersSnapshot.docs) {
      final userData = userDocument.data();

      final uid = userDocument.id;

      final attendanceId = '${uid}_$today';

      final attendanceDocument = await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .get();

      if (!attendanceDocument.exists) {
        continue;
      }

      final attendance = Map<String, dynamic>.from(attendanceDocument.data()!);

      attendance['attendanceId'] = attendanceDocument.id;

      attendance['userId'] = uid;

      attendance['name'] = userData['name']?.toString() ?? '';

      attendance['employeeId'] = userData['employeeId']?.toString() ?? '';

      attendance['role'] = userData['role']?.toString() ?? 'admin';

      final checkInTime = attendance['checkInTime'];

      if (checkInTime is Timestamp) {
        attendance['checkInTime'] = checkInTime.toDate();
      }

      records.add(attendance);
    }

    records.sort((a, b) {
      final aTime = _getTimestamp(a['checkInTime']);

      final bTime = _getTimestamp(b['checkInTime']);

      return bTime.compareTo(aTime);
    });

    return records;
  }
  // ==================================================
  // HELPER
  // ==================================================

  String getTodayDateKey() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  DateTime _getTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ==================================================
  // GET ATTENDANCE HISTORY DATES
  // ==================================================
  String _getDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistoryDatesByMonth(
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);

    final endDate = DateTime(month.year, month.month + 1, 1);

    // Get all active employees
    final usersSnapshot = await _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .get();

    int totalEmployees = 0;

    for (final userDoc in usersSnapshot.docs) {
      final role = userDoc.data()['role']?.toString().toLowerCase() ?? '';

      // Do not count Super Admin
      if (role != 'super_admin') {
        totalEmployees++;
      }
    }

    // Get attendance for selected month
    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where(
          'checkInTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('checkInTime', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('checkInTime', descending: true)
        .get();

    final Map<String, int> dateCounts = {};

    for (final doc in attendanceSnapshot.docs) {
      final data = doc.data();

      final checkInTime = data['checkInTime'];

      if (checkInTime == null) {
        continue;
      }

      try {
        final dateTime = checkInTime.toDate();

        final dateKey = _getDateKey(dateTime);

        dateCounts[dateKey] = (dateCounts[dateKey] ?? 0) + 1;
      } catch (_) {
        continue;
      }
    }

    final result = dateCounts.entries.map((entry) {
      final checkedIn = entry.value;

      final missing = totalEmployees - checkedIn;

      return {
        'date': entry.key,
        'count': checkedIn,
        'missing': missing < 0 ? 0 : missing,
      };
    }).toList();

    result.sort((a, b) {
      return b['date'].toString().compareTo(a['date'].toString());
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    // Get users, attendance, and teams in parallel
    final results = await Future.wait([
      _firestore.collection('users').where('isActive', isEqualTo: true).get(),
      _firestore.collection('attendance').where('date', isEqualTo: date).get(),
      _firestore.collection('teams').get(),
    ]);

    final usersSnapshot = results[0];
    final attendanceSnapshot = results[1];
    final teamsSnapshot = results[2];

    // ==========================================
    // TEAM NAME MAP
    // ==========================================

    final teamNameById = <String, String>{};

    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();

      teamNameById[teamDoc.id] = teamData['name']?.toString() ?? 'Unnamed Team';
    }

    // ==========================================
    // ATTENDANCE BY USER
    // ==========================================

    final attendanceByUser = <String, Map<String, dynamic>>{};

    for (final attendanceDoc in attendanceSnapshot.docs) {
      final data = attendanceDoc.data();

      final userId = data['userId']?.toString();

      if (userId != null && userId.isNotEmpty) {
        attendanceByUser[userId] = {'id': attendanceDoc.id, ...data};
      }
    }

    // ==========================================
    // CREATE RECORDS
    // ==========================================

    final records = <Map<String, dynamic>>[];

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userData = userDoc.data();

      final role = userData['role']?.toString() ?? '';
      final roleLower = role.toLowerCase();

      // Do not export Super Admin
      if (roleLower == 'super_admin') {
        continue;
      }

      final attendance = attendanceByUser[userId];

      // ==========================================
      // GET TEAM ID
      // ==========================================
      //
      // Priority:
      // 1. Attendance teamId
      // 2. User teamId
      //
      // This makes sure MISSING employees
      // still get their Team Name.
      // ==========================================

      final teamId = attendance?['teamId']?.toString().isNotEmpty == true
          ? attendance!['teamId'].toString()
          : userData['teamId']?.toString() ?? '';

      // ==========================================
      // GET TEAM NAME
      // ==========================================

      String teamName = '—';

      if (roleLower == 'admin' || roleLower == 'area_manager') {
        // Area Manager does not belong to a team
        teamName = 'Area Manager';
      } else if (teamId.isNotEmpty) {
        teamName = teamNameById[teamId] ?? '—';
      }

      // ==========================================
      // EMPLOYEE HAS ATTENDANCE
      // ==========================================

      if (attendance != null) {
        records.add({
          ...attendance,

          'userId': userId,
          'name': userData['name']?.toString() ?? 'Unknown',
          'employeeId': userData['employeeId']?.toString() ?? '—',
          'role': role,

          // Team Name only
          'teamId': teamId,
          'teamName': teamName,
        });
      }
      // ==========================================
      // EMPLOYEE IS MISSING
      // ==========================================
      else {
        records.add({
          'userId': userId,
          'name': userData['name']?.toString() ?? 'Unknown',
          'employeeId': userData['employeeId']?.toString() ?? '—',
          'role': role,

          // IMPORTANT:
          // Missing employee still gets Team Name
          'teamId': teamId,
          'teamName': teamName,

          'date': date,
          'attendanceStatus': 'missing',
          'timingStatus': '',
          'checkInTime': null,
          'latitude': null,
          'longitude': null,
        });
      }
    }

    // ==========================================
    // SORT
    // ==========================================

    records.sort((a, b) {
      final aPriority = _rolePriority(a['role']?.toString() ?? '');

      final bPriority = _rolePriority(b['role']?.toString() ?? '');

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return (a['name']?.toString() ?? '').toLowerCase().compareTo(
        (b['name']?.toString() ?? '').toLowerCase(),
      );
    });

    return records;
  }

  int _rolePriority(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'area_manager':
        return 1;

      case 'team_lead':
        return 2;

      case 'agent':
        return 3;

      default:
        return 4;
    }
  }
  // ==================================================
  // GET ALL ATTENDANCE RECORDS BY MONTH
  // ==================================================

  Future<List<Map<String, dynamic>>> getAttendanceByMonth(
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);

    final endDate = DateTime(month.year, month.month + 1, 1);

    final snapshot = await _firestore
        .collection('attendance')
        .where(
          'checkInTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('checkInTime', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('checkInTime')
        .get();

    return snapshot.docs.map((doc) {
      return {...doc.data(), 'attendanceId': doc.id};
    }).toList();
  }

  // ==================================================
  // GET MONTHLY ATTENDANCE FOR EXPORT
  // ==================================================
  // ==================================================
  // GET MONTHLY ATTENDANCE FOR EXPORT
  // INCLUDING MISSING EMPLOYEES
  // ==================================================
  Future<List<Map<String, dynamic>>> getMonthlyAttendanceForExport(
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    // ==========================================
    // GET USERS, ATTENDANCE AND TEAMS
    // ==========================================

    final results = await Future.wait([
      _firestore.collection('users').where('isActive', isEqualTo: true).get(),

      _firestore
          .collection('attendance')
          .where(
            'checkInTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('checkInTime', isLessThan: Timestamp.fromDate(endDate))
          .get(),

      _firestore.collection('teams').get(),
    ]);

    final usersSnapshot = results[0];
    final attendanceSnapshot = results[1];
    final teamsSnapshot = results[2];

    // ==========================================
    // TEAM NAME MAP
    // ==========================================

    final teamNameById = <String, String>{};

    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();

      teamNameById[teamDoc.id] = teamData['name']?.toString() ?? 'Unnamed Team';
    }

    // ==========================================
    // ACTIVE EMPLOYEES
    // ==========================================

    final users = <Map<String, dynamic>>[];

    for (final userDoc in usersSnapshot.docs) {
      final data = userDoc.data();

      final role = data['role']?.toString() ?? '';
      final roleLower = role.toLowerCase();

      // Do not export Super Admin
      if (roleLower == 'super_admin') {
        continue;
      }

      users.add({
        'userId': userDoc.id,
        'name': data['name']?.toString() ?? 'Unknown',
        'employeeId': data['employeeId']?.toString() ?? '—',
        'role': role,

        // IMPORTANT:
        // Keep user's teamId so missing attendance
        // can still show Team Name.
        'teamId': data['teamId']?.toString() ?? '',
      });
    }

    // ==========================================
    // MAP ATTENDANCE BY USER + DATE
    // ==========================================

    final attendanceByUserDate = <String, Map<String, dynamic>>{};

    final attendanceDates = <String>{};

    for (final attendanceDoc in attendanceSnapshot.docs) {
      final attendance = attendanceDoc.data();

      final userId = attendance['userId']?.toString() ?? '';

      final date = attendance['date']?.toString() ?? '';

      if (userId.isEmpty || date.isEmpty) {
        continue;
      }

      final key = '${userId}_$date';

      attendanceByUserDate[key] = {
        ...attendance,
        'attendanceId': attendanceDoc.id,
      };

      attendanceDates.add(date);
    }

    // ==========================================
    // CREATE RECORD FOR EVERY EMPLOYEE + DATE
    // ==========================================

    final records = <Map<String, dynamic>>[];

    for (final date in attendanceDates) {
      for (final user in users) {
        final userId = user['userId'].toString();

        final key = '${userId}_$date';

        final attendance = attendanceByUserDate[key];

        final role = user['role']?.toString() ?? '';

        final roleLower = role.toLowerCase();

        // ==========================================
        // GET TEAM ID
        // ==========================================
        //
        // Attendance teamId first.
        // If missing, use user's teamId.
        //
        // This is the important part that makes
        // missing agents show their Team Name.
        // ==========================================

        final attendanceTeamId = attendance?['teamId']?.toString() ?? '';

        final userTeamId = user['teamId']?.toString() ?? '';

        final teamId = attendanceTeamId.isNotEmpty
            ? attendanceTeamId
            : userTeamId;

        // ==========================================
        // GET TEAM NAME
        // ==========================================

        String teamName = '—';

        if (roleLower == 'admin' || roleLower == 'area_manager') {
          // Area Manager is not assigned to a team
          teamName = 'Area Manager';
        } else if (teamId.isNotEmpty) {
          teamName = teamNameById[teamId] ?? '—';
        }

        // ==========================================
        // EMPLOYEE CHECKED IN
        // ==========================================

        if (attendance != null) {
          records.add({
            ...attendance,

            'userId': userId,
            'name': user['name'],
            'employeeId': user['employeeId'],
            'role': role,

            // Team information
            'teamId': teamId,
            'teamName': teamName,
          });
        }
        // ==========================================
        // EMPLOYEE DID NOT CHECK IN
        // ==========================================
        else {
          records.add({
            'userId': userId,
            'name': user['name'],
            'employeeId': user['employeeId'],
            'role': role,

            // IMPORTANT:
            // Missing employee still gets Team Name
            'teamId': teamId,
            'teamName': teamName,

            'date': date,

            'checkInTime': null,
            'timingStatus': '',
            'attendanceStatus': 'missing',

            'latitude': null,
            'longitude': null,
          });
        }
      }
    }

    // ==========================================
    // SORT
    // DATE → ROLE → NAME
    // ==========================================

    records.sort((a, b) {
      final aDate = a['date']?.toString() ?? '';

      final bDate = b['date']?.toString() ?? '';

      final dateCompare = bDate.compareTo(aDate);

      if (dateCompare != 0) {
        return dateCompare;
      }

      final roleCompare = _rolePriority(
        a['role']?.toString() ?? '',
      ).compareTo(_rolePriority(b['role']?.toString() ?? ''));

      if (roleCompare != 0) {
        return roleCompare;
      }

      return (a['name']?.toString() ?? '').toLowerCase().compareTo(
        (b['name']?.toString() ?? '').toLowerCase(),
      );
    });

    return records;
  }
  // ==================================================
  // RESET ATTENDANCE
  // ==================================================

  Future<void> resetAttendance({required String attendanceId}) async {
    await _firestore.collection('attendance').doc(attendanceId).delete();
  }
}
