class TeamModel {
  final String id;
  final String name;
  final String areaManagerId;
  final String teamLeadId;
  final int memberCount;
  final bool isActive;

  const TeamModel({
    required this.id,
    required this.name,
    required this.areaManagerId,
    required this.teamLeadId,
    required this.memberCount,
    required this.isActive,
  });

  factory TeamModel.fromMap(String id, Map<String, dynamic> data) {
    return TeamModel(
      id: id,
      name: data['name']?.toString() ?? '',
      areaManagerId: data['areaManagerId']?.toString() ?? '',
      teamLeadId: data['teamLeadId']?.toString() ?? '',
      memberCount: data['memberCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'areaManagerId': areaManagerId,
      'teamLeadId': teamLeadId,
      'memberCount': memberCount,
      'isActive': isActive,
    };
  }
}
