class DailyTeamLocationModel {
  final String id;
  final String date;
  final String teamId;
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String assignedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyTeamLocationModel({
    required this.id,
    required this.date,
    required this.teamId,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.assignedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyTeamLocationModel.fromMap(String id, Map<String, dynamic> map) {
    return DailyTeamLocationModel(
      id: id,
      date: map['date']?.toString() ?? '',
      teamId: map['teamId']?.toString() ?? '',
      locationId: map['locationId']?.toString() ?? '',
      locationName: map['locationName']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 500,
      assignedBy: map['assignedBy']?.toString() ?? '',
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'teamId': teamId,
      'locationId': locationId,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'assignedBy': assignedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _dateTimeFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      return value.toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
