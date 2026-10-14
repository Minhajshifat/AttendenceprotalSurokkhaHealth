import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'leave_requests';

  // ==================================================
  // CREATE LEAVE REQUEST
  // ==================================================

  Future<String> createLeaveRequest({
    required String userId,
    required String employeeId,
    required String employeeName,
    required String role,
    required String teamId,
    required String teamName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required String reason,
  }) async {
    final document = await _firestore.collection(_collection).add({
      'userId': userId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'role': role,
      'teamId': teamId,
      'teamName': teamName,

      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      'reason': reason,

      // Overall status
      'status': 'pending',

      // Team Lead approval
      'teamLeadStatus': 'pending',
      'teamLeadId': '',
      'teamLeadComment': '',

      // Area Manager approval
      'areaManagerStatus': 'pending',
      'areaManagerId': '',
      'areaManagerComment': '',

      // Super Admin approval
      'superAdminStatus': 'pending',
      'superAdminId': '',
      'superAdminComment': '',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // ==================================================
  // GET EMPLOYEE LEAVE REQUESTS
  // ==================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyLeaveRequests(
    String userId,
  ) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================================================
  // CANCEL LEAVE REQUEST
  // ==================================================

  Future<void> cancelLeaveRequest({required String leaveId}) async {
    await _firestore.collection(_collection).doc(leaveId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
