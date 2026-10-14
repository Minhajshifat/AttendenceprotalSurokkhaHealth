import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // GET USER BY FIREBASE UID
  // ==========================================

  Future<AppUser?> getUser(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return AppUser.fromMap(document.id, document.data()!);
  }

  // ==========================================
  // GET EMPLOYEE BY GOOGLE EMAIL
  // ==========================================

  Future<AppUser?> getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    final document = query.docs.first;

    return AppUser.fromMap(document.id, document.data());
  }
}
