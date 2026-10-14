import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // CREATE EMPLOYEE
  // ==========================================

  Future<void> createEmployee({
    required String employeeId,
    required String name,
    required String email,
    required String role,
    required String designation,
    bool isActive = true,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Same email already exists কিনা check
    final existingUser = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw Exception('An employee with this Google email already exists.');
    }

    // Temporary Firestore document ID
    final docRef = _firestore.collection('users').doc();

    final employee = AppUser(
      uid: docRef.id,
      employeeId: employeeId.trim(),
      name: name.trim(),
      email: normalizedEmail,
      role: role,
      designation: designation.trim(),
      teamId: '',
      teamIds: const [],
      teamLeadId: '',
      adminId: '',
      accountStatus: isActive ? 'active' : 'inactive',
      isActive: isActive,
    );

    await docRef.set(employee.toMap());
  }

  // ==========================================
  // UPDATE EMPLOYEE
  // ==========================================

  Future<void> updateEmployee({required AppUser employee}) async {
    final normalizedEmail = employee.email.trim().toLowerCase();

    await _firestore.collection('users').doc(employee.uid).update({
      ...employee.toMap(),
      'email': normalizedEmail,
    });
  }

  // ==========================================
  // UPDATE EMPLOYEE STATUS
  // ==========================================

  Future<void> updateEmployeeStatus({
    required String uid,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
      'accountStatus': isActive ? 'active' : 'inactive',
    });
  }
}
