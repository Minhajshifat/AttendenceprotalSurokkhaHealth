import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================
  // GOOGLE SIGN IN
  // Employees:
  // Agent / Team Lead / Area Manager
  // ============================

  Future<UserCredential> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('email');

    googleProvider.setCustomParameters({'prompt': 'select_account'});

    UserCredential credential;

    try {
      credential = await _auth.signInWithPopup(googleProvider);
    } catch (e) {
      rethrow;
    }

    final user = credential.user;

    if (user == null || user.email == null) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to identify this Google account.',
      );
    }

    try {
      // ==========================================
      // FIND EMPLOYEE BY EMAIL
      // ==========================================

      final email = user.email!.trim().toLowerCase();

      final employeeQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // Employee not registered
      if (employeeQuery.docs.isEmpty) {
        await _auth.signOut();

        throw FirebaseAuthException(
          code: 'unauthorized-user',
          message: 'This Google account is not registered as an employee.',
        );
      }

      final userDoc = employeeQuery.docs.first;
      final userData = userDoc.data();

      // ==========================================
      // CHECK ACTIVE STATUS
      // ==========================================

      final isActive = userData['isActive'] ?? true;

      if (isActive != true) {
        await _auth.signOut();

        throw FirebaseAuthException(
          code: 'inactive-user',
          message: 'This employee account is inactive.',
        );
      }

      // ==========================================
      // PREVENT SUPER ADMIN GOOGLE LOGIN
      // ==========================================

      final role = userData['role']?.toString().toLowerCase().trim() ?? '';

      if (role == 'super_admin') {
        await _auth.signOut();

        throw FirebaseAuthException(
          code: 'invalid-login-method',
          message: 'Please use Super Admin login.',
        );
      }

      return credential;
    } catch (e) {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      rethrow;
    }
  }
  // ============================
  // SUPER ADMIN LOGIN
  // Email + Password
  // ============================

  Future<UserCredential> loginSuperAdmin({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ============================
  // LOGOUT
  // ============================

  Future<void> logout() async {
    await _auth.signOut();
  }
}
