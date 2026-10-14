import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_team_location_model.dart';
import '../models/field_location_model.dart';

class DailyTeamLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================================================
  // COLLECTIONS
  // ==================================================

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _firestore.collection('daily_team_locations');

  CollectionReference<Map<String, dynamic>> get _currentLocations =>
      _firestore.collection('team_current_locations');

  // ==================================================
  // DATE KEY
  // ==================================================

  String getDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String getTodayDateKey() {
    return getDateKey(DateTime.now());
  }

  // ==================================================
  // ASSIGN LOCATION TO TEAM
  // ==================================================
  //
  // This does TWO things:
  //
  // 1. Saves assignment history
  // 2. Updates team's current location
  //
  // The current location will remain active
  // until another location is assigned.
  // ==================================================

  Future<void> assignLocationToTeam({
    required String teamId,
    required FieldLocationModel location,
    required String assignedBy,
  }) async {
    final cleanTeamId = teamId.trim();
    final cleanAssignedBy = assignedBy.trim();

    if (cleanTeamId.isEmpty) {
      throw Exception('Team is required.');
    }

    if (cleanAssignedBy.isEmpty) {
      throw Exception('Assigned by user is required.');
    }

    if (!location.isActive) {
      throw Exception('This field location is inactive.');
    }

    final now = DateTime.now();
    final date = getDateKey(now);

    // ==================================================
    // 1. SAVE ASSIGNMENT HISTORY
    // ==================================================

    final historyDocumentId = '${date}_${cleanTeamId}_${location.id}';

    await _assignments.doc(historyDocumentId).set({
      'date': date,
      'teamId': cleanTeamId,

      'locationId': location.id,
      'locationName': location.name,

      'latitude': location.latitude,
      'longitude': location.longitude,
      'radiusMeters': location.radiusMeters,

      'assignedBy': cleanAssignedBy,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ==================================================
    // 2. UPDATE CURRENT TEAM LOCATION
    // ==================================================

    await _currentLocations.doc(cleanTeamId).set({
      'teamId': cleanTeamId,

      'locationId': location.id,
      'locationName': location.name,

      'latitude': location.latitude,
      'longitude': location.longitude,
      'radiusMeters': location.radiusMeters,

      'assignedBy': cleanAssignedBy,

      'assignedDate': date,

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // GET CURRENT LOCATION FOR TEAM
  // ==================================================

  Future<DailyTeamLocationModel?> getCurrentTeamLocation(String teamId) async {
    final cleanTeamId = teamId.trim();

    if (cleanTeamId.isEmpty) {
      return null;
    }

    final document = await _currentLocations.doc(cleanTeamId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return DailyTeamLocationModel.fromMap(document.id, document.data()!);
  }

  // ==================================================
  // GET CURRENT LOCATION FOR USER
  // ==================================================
  //
  // User
  //   ↓
  // teamId
  //   ↓
  // current team location
  //
  // The same location continues until changed.
  // ==================================================

  Future<DailyTeamLocationModel?> getCurrentLocationForUser(
    String userId,
  ) async {
    final userDocument = await _firestore
        .collection('users')
        .doc(userId.trim())
        .get();

    if (!userDocument.exists || userDocument.data() == null) {
      return null;
    }

    final userData = userDocument.data()!;

    // ==================================================
    // SINGULAR TEAM ID
    // ==================================================

    final teamId = userData['teamId']?.toString().trim() ?? '';

    if (teamId.isNotEmpty) {
      final location = await getCurrentTeamLocation(teamId);

      if (location != null) {
        return location;
      }
    }

    // ==================================================
    // MULTIPLE TEAM IDS
    // ==================================================

    final rawTeamIds = userData['teamIds'];

    if (rawTeamIds is List) {
      for (final value in rawTeamIds) {
        final multipleTeamId = value.toString().trim();

        if (multipleTeamId.isEmpty) {
          continue;
        }

        final location = await getCurrentTeamLocation(multipleTeamId);

        if (location != null) {
          return location;
        }
      }
    }

    return null;
  }

  // ==================================================
  // GET TODAY'S ASSIGNMENT HISTORY
  // ==================================================

  Future<List<DailyTeamLocationModel>> getTodayAssignments() async {
    return getAssignmentsForDate(getTodayDateKey());
  }

  // ==================================================
  // GET ASSIGNMENTS FOR DATE
  // ==================================================

  Future<List<DailyTeamLocationModel>> getAssignmentsForDate(
    String date,
  ) async {
    final snapshot = await _assignments.where('date', isEqualTo: date).get();

    final assignments = snapshot.docs.map((doc) {
      return DailyTeamLocationModel.fromMap(doc.id, doc.data());
    }).toList();

    assignments.sort(
      (a, b) =>
          a.locationName.toLowerCase().compareTo(b.locationName.toLowerCase()),
    );

    return assignments;
  }

  // ==================================================
  // REMOVE CURRENT TEAM LOCATION
  // ==================================================
  //
  // Use this only when you explicitly want
  // the team to have NO assigned location.
  // ==================================================

  Future<void> removeCurrentTeamLocation(String teamId) async {
    final cleanTeamId = teamId.trim();

    if (cleanTeamId.isEmpty) {
      return;
    }

    await _currentLocations.doc(cleanTeamId).delete();
  }

  // ==================================================
  // CHECK CURRENT LOCATION
  // ==================================================

  Future<bool> hasCurrentLocation(String teamId) async {
    final location = await getCurrentTeamLocation(teamId);

    return location != null;
  }

  // ==================================================
  // GET ALL CURRENT TEAM LOCATIONS
  // ==================================================

  Future<List<DailyTeamLocationModel>> getAllCurrentTeamLocations() async {
    final snapshot = await _currentLocations.get();

    final locations = snapshot.docs.map((doc) {
      return DailyTeamLocationModel.fromMap(doc.id, doc.data());
    }).toList();

    locations.sort(
      (a, b) =>
          a.locationName.toLowerCase().compareTo(b.locationName.toLowerCase()),
    );

    return locations;
  }

  // ==================================================
  // GET CURRENT LOCATION FOR SPECIFIC TEAM
  // ==================================================

  Future<FieldLocationModel?> getFieldLocationForTeam(String teamId) async {
    final currentLocation = await getCurrentTeamLocation(teamId);

    if (currentLocation == null) {
      return null;
    }

    final locationDocument = await _firestore
        .collection('field_locations')
        .doc(currentLocation.locationId)
        .get();

    if (!locationDocument.exists || locationDocument.data() == null) {
      return null;
    }

    return FieldLocationModel.fromMap(
      locationDocument.id,
      locationDocument.data()!,
    );
  }
}
