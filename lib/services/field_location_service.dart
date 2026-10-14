import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/field_location_model.dart';

class FieldLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('field_locations');

  // ==================================================
  // CREATE FIELD LOCATION
  // ==================================================

  Future<void> createFieldLocation({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String areaManagerId,
    String? teamId,
    String? assignedUserId,
  }) async {
    final doc = _collection.doc();

    await doc.set({
      'name': name.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'areaManagerId': areaManagerId.trim(),

      // NEW
      'teamId': teamId?.trim(),

      // OLD - backward compatibility
      'assignedUserId': assignedUserId?.trim(),

      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // UPDATE FIELD LOCATION
  // ==================================================

  Future<void> updateFieldLocation({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String areaManagerId,
    String? teamId,
    String? assignedUserId,
    required bool isActive,
  }) async {
    await _collection.doc(id).update({
      'name': name.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'areaManagerId': areaManagerId.trim(),

      // NEW
      'teamId': teamId?.trim(),

      // OLD
      'assignedUserId': assignedUserId?.trim(),

      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // DELETE
  // ==================================================

  Future<void> deleteFieldLocation(String id) async {
    await _collection.doc(id).delete();
  }

  // ==================================================
  // GET ALL
  // ==================================================

  Stream<List<FieldLocationModel>> getFieldLocations() {
    return _collection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FieldLocationModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // ==================================================
  // GET AREA MANAGER LOCATIONS
  // ==================================================

  Stream<List<FieldLocationModel>> getAreaManagerLocations(
    String areaManagerId,
  ) {
    return _collection
        .where('areaManagerId', isEqualTo: areaManagerId.trim())
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FieldLocationModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // ==================================================
  // GET SINGLE LOCATION
  // ==================================================

  Future<FieldLocationModel?> getFieldLocation(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return FieldLocationModel.fromMap(doc.id, doc.data()!);
  }

  // ==================================================
  // GET LOCATION FOR USER
  //
  // Priority:
  // 1. Team assigned location
  // 2. Old individual assigned location
  // ==================================================

  Future<FieldLocationModel?> getLocationForUser(String userId) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(userId.trim())
        .get();

    if (!userDoc.exists || userDoc.data() == null) {
      return null;
    }

    final userData = userDoc.data()!;

    // ==================================================
    // TEAM ID
    // ==================================================

    final teamId = userData['teamId']?.toString().trim();

    // ==================================================
    // TEAM LOCATION
    // ==================================================

    if (teamId != null && teamId.isNotEmpty) {
      final teamLocation = await _collection
          .where('teamId', isEqualTo: teamId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (teamLocation.docs.isNotEmpty) {
        final doc = teamLocation.docs.first;

        return FieldLocationModel.fromMap(doc.id, doc.data());
      }
    }

    // ==================================================
    // OLD INDIVIDUAL LOCATION
    // ==================================================

    return getAssignedLocation(userId);
  }

  // ==================================================
  // OLD: GET ASSIGNED LOCATION
  // ==================================================

  Future<FieldLocationModel?> getAssignedLocation(String userId) async {
    final snapshot = await _collection
        .where('assignedUserId', isEqualTo: userId.trim())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return FieldLocationModel.fromMap(doc.id, doc.data());
  }

  // ==================================================
  // ASSIGN LOCATION TO TEAM
  // ==================================================

  Future<void> assignLocationToTeam({
    required String locationId,
    required String teamId,
  }) async {
    final locationRef = _collection.doc(locationId);

    final locationDoc = await locationRef.get();

    if (!locationDoc.exists) {
      throw Exception('Field location not found.');
    }

    final data = locationDoc.data();

    if (data?['isActive'] != true) {
      throw Exception('This field location is inactive.');
    }

    await locationRef.update({
      'teamId': teamId.trim(),

      // Remove old individual assignment
      'assignedUserId': null,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // REMOVE TEAM ASSIGNMENT
  // ==================================================

  Future<void> removeTeamAssignment(String locationId) async {
    await _collection.doc(locationId).update({
      'teamId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // ASSIGN LOCATION TO USER
  // OLD / BACKWARD COMPATIBILITY
  // ==================================================

  Future<void> assignLocationToUser({
    required String locationId,
    required String userId,
  }) async {
    final locationRef = _collection.doc(locationId);

    final locationDoc = await locationRef.get();

    if (!locationDoc.exists) {
      throw Exception('Field location not found.');
    }

    final locationData = locationDoc.data();

    if (locationData?['isActive'] != true) {
      throw Exception('This field location is inactive.');
    }

    await locationRef.update({
      'assignedUserId': userId.trim(),
      'teamId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // REMOVE USER ASSIGNMENT
  // ==================================================

  Future<void> removeLocationAssignment(String locationId) async {
    await _collection.doc(locationId).update({
      'assignedUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
