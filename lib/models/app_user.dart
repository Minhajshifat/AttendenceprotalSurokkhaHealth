class AppUser {
  final String uid;
  final String employeeId;
  final String name;
  final String email;
  final String role;
  final String designation;
  final String teamId;
  final List<String> teamIds;
  final String teamLeadId;
  final String adminId;
  final String accountStatus;
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    required this.designation,
    required this.teamId,
    required this.teamIds,
    required this.teamLeadId,
    required this.adminId,
    required this.accountStatus,
    required this.isActive,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      employeeId: data['employeeId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',

      // Supports:
      // agent
      // team_lead
      // admin
      // office_employee
      role: data['role']?.toString() ?? '',

      designation: data['designation']?.toString() ?? '',
      teamId: data['teamId']?.toString() ?? '',

      teamIds:
          (data['teamIds'] as List<dynamic>?)
              ?.map((teamId) => teamId.toString())
              .where((teamId) => teamId.trim().isNotEmpty)
              .toList() ??
          [],

      teamLeadId: data['teamLeadId']?.toString() ?? '',
      adminId: data['adminId']?.toString() ?? '',
      accountStatus: data['accountStatus']?.toString() ?? 'active',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'role': role,
      'designation': designation,
      'teamId': teamId,
      'teamIds': teamIds,
      'teamLeadId': teamLeadId,
      'adminId': adminId,
      'accountStatus': accountStatus,
      'isActive': isActive,
    };
  }
}
