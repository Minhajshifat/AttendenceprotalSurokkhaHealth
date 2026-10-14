import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String userId;
  final String employeeId;
  final String employeeName;
  final String role;
  final String teamId;
  final String teamName;

  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;

  final String status;

  final String teamLeadStatus;
  final String teamLeadId;
  final String teamLeadComment;

  final String areaManagerStatus;
  final String areaManagerId;
  final String areaManagerComment;

  final String superAdminStatus;
  final String superAdminId;
  final String superAdminComment;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.teamId,
    required this.teamName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.teamLeadStatus,
    required this.teamLeadId,
    required this.teamLeadComment,
    required this.areaManagerStatus,
    required this.areaManagerId,
    required this.areaManagerComment,
    required this.superAdminStatus,
    required this.superAdminId,
    required this.superAdminComment,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaveRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return LeaveRequest(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      employeeId: data['employeeId']?.toString() ?? '',
      employeeName: data['employeeName']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      teamId: data['teamId']?.toString() ?? '',
      teamName: data['teamName']?.toString() ?? '',
      leaveType: data['leaveType']?.toString() ?? '',
      startDate: _dateFromFirestore(data['startDate']),
      endDate: _dateFromFirestore(data['endDate']),
      totalDays: data['totalDays'] is int
          ? data['totalDays']
          : int.tryParse(data['totalDays']?.toString() ?? '') ?? 0,
      reason: data['reason']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      teamLeadStatus: data['teamLeadStatus']?.toString() ?? 'pending',
      teamLeadId: data['teamLeadId']?.toString() ?? '',
      teamLeadComment: data['teamLeadComment']?.toString() ?? '',
      areaManagerStatus: data['areaManagerStatus']?.toString() ?? 'pending',
      areaManagerId: data['areaManagerId']?.toString() ?? '',
      areaManagerComment: data['areaManagerComment']?.toString() ?? '',
      superAdminStatus: data['superAdminStatus']?.toString() ?? 'pending',
      superAdminId: data['superAdminId']?.toString() ?? '',
      superAdminComment: data['superAdminComment']?.toString() ?? '',
      createdAt: _nullableDate(data['createdAt']),
      updatedAt: _nullableDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'status': status,
      'teamLeadStatus': teamLeadStatus,
      'teamLeadId': teamLeadId,
      'teamLeadComment': teamLeadComment,
      'areaManagerStatus': areaManagerStatus,
      'areaManagerId': areaManagerId,
      'areaManagerComment': areaManagerComment,
      'superAdminStatus': superAdminStatus,
      'superAdminId': superAdminId,
      'superAdminComment': superAdminComment,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _dateFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
