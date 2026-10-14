class FieldLocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String areaManagerId;

  // NEW: Team assigned to this location
  final String? teamId;

  // OLD: Keep this for backward compatibility
  final String? assignedUserId;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FieldLocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.areaManagerId,
    this.teamId,
    this.assignedUserId,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory FieldLocationModel.fromMap(String id, Map<String, dynamic> map) {
    return FieldLocationModel(
      id: id,
      name: map['name']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 500,

      areaManagerId: map['areaManagerId']?.toString() ?? '',

      // NEW
      teamId: map['teamId']?.toString(),

      // OLD - kept for existing locations
      assignedUserId: map['assignedUserId']?.toString(),

      isActive: map['isActive'] == true,

      createdAt: _dateTimeFromValue(map['createdAt']),

      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'areaManagerId': areaManagerId,

      // NEW
      'teamId': teamId,

      // OLD
      'assignedUserId': assignedUserId,

      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  FieldLocationModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? areaManagerId,
    String? teamId,
    String? assignedUserId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldLocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      areaManagerId: areaManagerId ?? this.areaManagerId,

      // NEW
      teamId: teamId ?? this.teamId,

      assignedUserId: assignedUserId ?? this.assignedUserId,

      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _dateTimeFromValue(dynamic value) {
    if (value == null) return null;

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
