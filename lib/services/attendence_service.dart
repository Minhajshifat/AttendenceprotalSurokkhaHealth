import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/field_location_model.dart';
import 'field_location_service.dart';
import '../models/daily_team_location_model.dart';
import 'daily_team_location_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FieldLocationService _fieldLocationService = FieldLocationService();
  final DailyTeamLocationService _dailyTeamLocationService =
      DailyTeamLocationService();

  // ==================================================
  // ATTENDANCE TIME
  // ==================================================

  static const int defaultStartHour = 10;
  static const int defaultStartMinute = 0;

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
  // TIMING STATUS
  // ==================================================

  String calculateTimingStatus({
    required DateTime checkInTime,
    int startHour = defaultStartHour,
    int startMinute = defaultStartMinute,
  }) {
    final scheduledStart = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      startHour,
      startMinute,
    );

    if (checkInTime.isAfter(scheduledStart)) {
      return 'late';
    }

    return 'on_time';
  }

  // ==================================================
  // HAS TODAY ATTENDANCE
  // ==================================================

  Future<bool> hasTodayAttendance(String userId) async {
    final dateKey = _getDateKey(DateTime.now());

    final doc = await _firestore
        .collection('attendance')
        .doc('${userId}_$dateKey')
        .get();

    return doc.exists;
  }

  // ==================================================
  // GET TODAY STATUS
  // ==================================================

  Future<String?> getTodayStatus(String userId) async {
    final dateKey = _getDateKey(DateTime.now());

    final doc = await _firestore
        .collection('attendance')
        .doc('${userId}_$dateKey')
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data()?['attendanceStatus']?.toString();
  }

  // ==================================================
  // GET TODAY ATTENDANCE
  // ==================================================

  Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    final dateKey = _getDateKey(DateTime.now());

    final doc = await _firestore
        .collection('attendance')
        .doc('${userId}_$dateKey')
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  // ==================================================
  // OFFICE LOCATION
  // ==================================================

  Future<Map<String, dynamic>?> getOfficeLocation() async {
    final doc = await _firestore
        .collection('office_settings')
        .doc('location')
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  // ==================================================
  // CHECK OFFICE LOCATION
  // ==================================================

  Future<bool> isInsideOffice({
    required double latitude,
    required double longitude,
  }) async {
    final office = await getOfficeLocation();

    if (office == null) {
      throw Exception('Office location has not been configured.');
    }

    final officeLatitude = (office['latitude'] as num?)?.toDouble();

    final officeLongitude = (office['longitude'] as num?)?.toDouble();

    final radius = (office['radiusMeters'] as num?)?.toDouble();

    if (officeLatitude == null || officeLongitude == null || radius == null) {
      throw Exception('Office location configuration is invalid.');
    }

    final distance = calculateDistanceMeters(
      latitude1: latitude,
      longitude1: longitude,
      latitude2: officeLatitude,
      longitude2: officeLongitude,
    );

    return distance <= radius;
  }

  // ==================================================
  // GET ASSIGNED FIELD LOCATION
  // ==================================================

  Future<FieldLocationModel?> getAssignedFieldLocation(String userId) async {
    // This method is kept for backward compatibility.
    // New attendance validation uses the user's team
    // and the current team location.
    return await _fieldLocationService.getAssignedLocation(userId);
  }
  // ==================================================
  // GET CURRENT TEAM LOCATION
  // ==================================================

  Future<DailyTeamLocationModel?> getCurrentTeamLocation(String teamId) async {
    return await _dailyTeamLocationService.getCurrentTeamLocation(teamId);
  }

  // ==================================================
  // GET CURRENT LOCATION FOR USER
  // ==================================================

  Future<DailyTeamLocationModel?> getCurrentLocationForUser(
    AppUser user,
  ) async {
    final teamId = user.teamId.trim();

    if (teamId.isNotEmpty) {
      final location = await getCurrentTeamLocation(teamId);

      if (location != null) {
        return location;
      }
    }

    // Support multiple team IDs if present.
    for (final teamId in user.teamIds) {
      final cleanTeamId = teamId.trim();

      if (cleanTeamId.isEmpty) {
        continue;
      }

      final location = await getCurrentTeamLocation(cleanTeamId);

      if (location != null) {
        return location;
      }
    }

    return null;
  }

  // ==================================================
  // CHECK ASSIGNED FIELD LOCATION
  // ==================================================
  Future<bool> isInsideAssignedFieldLocation({
    required AppUser user,
    required double latitude,
    required double longitude,
  }) async {
    final currentLocation = await getCurrentLocationForUser(user);

    if (currentLocation == null) {
      throw Exception('No field location has been assigned to your team.');
    }

    final distance = calculateDistanceMeters(
      latitude1: latitude,
      longitude1: longitude,
      latitude2: currentLocation.latitude,
      longitude2: currentLocation.longitude,
    );

    return distance <= currentLocation.radiusMeters;
  }

  // ==================================================
  // GET DISTANCE FROM ASSIGNED FIELD LOCATION
  // ==================================================
  Future<double> getDistanceFromAssignedFieldLocation({
    required AppUser user,
    required double latitude,
    required double longitude,
  }) async {
    final currentLocation = await getCurrentLocationForUser(user);

    if (currentLocation == null) {
      throw Exception('No field location has been assigned to your team.');
    }

    return calculateDistanceMeters(
      latitude1: latitude,
      longitude1: longitude,
      latitude2: currentLocation.latitude,
      longitude2: currentLocation.longitude,
    );
  }
  // ==================================================
  // VALIDATE ATTENDANCE LOCATION
  // ==================================================

  // ==================================================
  // VALIDATE ATTENDANCE LOCATION
  // ==================================================

  Future<String> validateAttendanceLocation({
    required AppUser user,
    required double latitude,
    required double longitude,
  }) async {
    final role = user.role
        .toLowerCase()
        .trim()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');

    // ==================================================
    // AGENT
    // ==================================================

    if (role == 'agent') {
      final insideFieldLocation = await isInsideAssignedFieldLocation(
        user: user,
        latitude: latitude,
        longitude: longitude,
      );

      if (!insideFieldLocation) {
        throw Exception('You are outside your assigned field location.');
      }

      return 'field';
    }

    // ==================================================
    // TEAM LEAD
    // ==================================================

    if (role == 'teamlead') {
      return 'field';
    }

    // ==================================================
    // AREA MANAGER
    // ==================================================

    if (role == 'admin' || role == 'areamanager') {
      return 'unrestricted';
    }

    // ==================================================
    // BACKWARD COMPATIBILITY
    // ==================================================

    return 'legacy';
  }
  // ==================================================
  // REAL-TIME TODAY ATTENDANCE
  // ==================================================

  Stream<Map<String, dynamic>?> getTodayAttendanceStream(String userId) {
    final dateKey = _getDateKey(DateTime.now());

    return _firestore
        .collection('attendance')
        .doc('${userId}_$dateKey')
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }

          return doc.data();
        });
  }
  // ==================================================
  // CREATE ATTENDANCE
  // ==================================================

  Future<void> createAttendance({
    required String userId,
    required String employeeId,
    required String teamId,
    String teamLeadId = '',
    String areaManagerId = '',
    required double latitude,
    required double longitude,
    required double accuracy,
    String note = '',
    String attendanceLocationType = 'legacy',
    String area = '',
  }) async {
    final now = DateTime.now();

    final dateKey = _getDateKey(now);

    final attendanceRef = _firestore
        .collection('attendance')
        .doc('${userId}_$dateKey');

    final existingAttendance = await attendanceRef.get();

    if (existingAttendance.exists) {
      throw Exception('You have already submitted attendance for today.');
    }

    final timingStatus = calculateTimingStatus(checkInTime: now);

    await attendanceRef.set({
      'userId': userId,
      'employeeId': employeeId,
      'teamId': teamId,
      'teamLeadId': teamLeadId,
      'areaManagerId': areaManagerId,

      'date': dateKey,

      'checkInTime': Timestamp.fromDate(now),

      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,

      'timingStatus': timingStatus,

      'attendanceStatus': 'pending',

      'attendanceLocationType': attendanceLocationType,

      'teamLeadReviewed': false,
      'teamLeadReviewedBy': null,
      'teamLeadReviewedAt': null,

      'areaManagerReviewed': false,
      'areaManagerReviewedBy': null,
      'areaManagerReviewedAt': null,

      'approvedBy': null,
      'approvedByRole': null,
      'approvedAt': null,

      'note': note.trim(),
      'area': area.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // GET TEAM MEMBERS' TODAY ATTENDANCE
  // ==================================================

  Future<List<Map<String, dynamic>>> getTeamMembersAttendance({
    required String teamId,
    required String currentUserId,
  }) async {
    final dateKey = getTodayDateKey();

    final usersSnapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'agent')
        .get();

    final result = <Map<String, dynamic>>[];

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final uid = userDoc.id;

      final attendanceDoc = await _firestore
          .collection('attendance')
          .doc('${uid}_$dateKey')
          .get();

      result.add({
        'uid': uid,
        'name': userData['name']?.toString() ?? '',
        'employeeId': userData['employeeId']?.toString() ?? '',
        'teamId': userData['teamId']?.toString() ?? '',
        'attendance': attendanceDoc.exists ? attendanceDoc.data() : null,
      });
    }

    result.sort(
      (a, b) => a['name'].toString().toLowerCase().compareTo(
        b['name'].toString().toLowerCase(),
      ),
    );

    return result;
  }

  // ==================================================
  // REAL-TIME TEAM MEMBERS' ATTENDANCE
  // ==================================================

  Stream<List<Map<String, dynamic>>> getTeamMembersAttendanceStream({
    required String teamId,
  }) {
    final dateKey = getTodayDateKey();

    return _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'agent')
        .snapshots()
        .asyncMap((usersSnapshot) async {
          final result = <Map<String, dynamic>>[];

          for (final userDoc in usersSnapshot.docs) {
            final userData = userDoc.data();
            final uid = userDoc.id;

            final attendanceDoc = await _firestore
                .collection('attendance')
                .doc('${uid}_$dateKey')
                .get();

            result.add({
              'uid': uid,
              'name': userData['name']?.toString() ?? '',
              'employeeId': userData['employeeId']?.toString() ?? '',
              'teamId': userData['teamId']?.toString() ?? '',
              'attendance': attendanceDoc.exists ? attendanceDoc.data() : null,
            });
          }

          result.sort(
            (a, b) => a['name'].toString().toLowerCase().compareTo(
              b['name'].toString().toLowerCase(),
            ),
          );

          return result;
        });
  }

  // ==================================================
  // TEAM LEAD REVIEW
  // ==================================================

  Future<void> reviewByTeamLead({
    required String attendanceId,
    required String reviewedBy,
  }) async {
    final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

    final doc = await attendanceRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    final data = doc.data();

    if (data?['teamLeadReviewed'] == true) {
      return;
    }

    await attendanceRef.update({
      'teamLeadReviewed': true,
      'teamLeadReviewedBy': reviewedBy,
      'teamLeadReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // AREA MANAGER REVIEW
  // ==================================================

  Future<void> reviewByAreaManager({
    required String attendanceId,
    required String reviewedBy,
  }) async {
    final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

    final doc = await attendanceRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    final data = doc.data();

    if (data?['areaManagerReviewed'] == true) {
      return;
    }

    await attendanceRef.update({
      'areaManagerReviewed': true,
      'areaManagerReviewedBy': reviewedBy,
      'areaManagerReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // SUPER ADMIN FINAL APPROVAL
  // ==================================================

  Future<void> approveAttendance({
    required String attendanceId,
    required String approvedBy,
    required String approvedByRole,
  }) async {
    final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

    final doc = await attendanceRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    await attendanceRef.update({
      'attendanceStatus': 'approved',

      'approvedBy': approvedBy,
      'approvedByRole': approvedByRole,
      'approvedAt': FieldValue.serverTimestamp(),

      'approvalStatus': 'approved',
      'superAdminApproved': true,
    });
  }

  // ==================================================
  // SUPER ADMIN FINAL REJECTION
  // ==================================================

  Future<void> rejectAttendance({
    required String attendanceId,
    required String rejectedBy,
    required String rejectedByRole,
  }) async {
    final attendanceRef = _firestore.collection('attendance').doc(attendanceId);

    final doc = await attendanceRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    await attendanceRef.update({
      'attendanceStatus': 'rejected',

      'approvedBy': rejectedBy,
      'approvedByRole': rejectedByRole,
      'approvedAt': FieldValue.serverTimestamp(),

      'approvalStatus': 'rejected',
      'superAdminApproved': false,
    });
  }

  // ==================================================
  // CALCULATE DISTANCE
  // ==================================================

  double calculateDistanceMeters({
    required double latitude1,
    required double longitude1,
    required double latitude2,
    required double longitude2,
  }) {
    const earthRadius = 6371000.0;

    final lat1 = latitude1 * pi / 180;
    final lat2 = latitude2 * pi / 180;

    final deltaLat = (latitude2 - latitude1) * pi / 180;

    final deltaLon = (longitude2 - longitude1) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // ==================================================
  // GET ATTENDANCE HISTORY
  // ==================================================

  Future<List<Map<String, dynamic>>> getAttendanceHistory(
    String userId, {
    int days = 30,
  }) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .get();

    final history = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();

    history.sort((a, b) {
      final aTime = a['checkInTime'] as Timestamp?;

      final bTime = b['checkInTime'] as Timestamp?;

      if (aTime == null && bTime == null) {
        return 0;
      }

      if (aTime == null) {
        return 1;
      }

      if (bTime == null) {
        return -1;
      }

      return bTime.compareTo(aTime);
    });

    return history.take(days).toList();
  }
}
