import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_user.dart';
import '../../services/employee_service.dart';
import '../../widgets/super_admin/employee_form_dialog.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmployeeService _employeeService = EmployeeService();

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Employee Management',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showEmployeeDialog();
        },
        backgroundColor: const Color(0xFF155084),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          'Add Employee',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load employees'));
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF155084)),
                  );
                }

                final employees = snapshot.data!.docs
                    .map((doc) => AppUser.fromMap(doc.id, doc.data()))
                    .where(
                      (user) =>
                          user.role != 'super_admin' && _matchesSearch(user),
                    )
                    .toList();

                employees.sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

                if (employees.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildEmployeeList(employees);
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(AppUser user) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();

    return user.name.toLowerCase().contains(query) ||
        user.employeeId.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query) ||
        user.role.toLowerCase().contains(query);
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by name, employee ID or email',
          hintStyle: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF98A1AD),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF687385),
          ),
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF155084), width: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList(List<AppUser> employees) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        if (isDesktop) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildDesktopTable(employees),
              const SizedBox(height: 80),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildMobileCard(employees[index]);
          },
        );
      },
    );
  }

  Widget _buildDesktopTable(List<AppUser> employees) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 32,
            horizontalMargin: 22,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFBFCFE)),
            columns: const [
              DataColumn(label: Text('EMPLOYEE')),
              DataColumn(label: Text('EMPLOYEE ID')),
              DataColumn(label: Text('ROLE')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: employees.map((employee) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFFEAF3FA),
                          child: Text(
                            _initials(employee.name),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF155084),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF172B4D),
                              ),
                            ),
                            Text(
                              employee.email,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFF7A8491),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      employee.employeeId,
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                  DataCell(_roleBadge(employee.role)),
                  DataCell(_statusBadge(employee)),
                  DataCell(
                    IconButton(
                      tooltip: 'Edit Employee',
                      onPressed: () {
                        _showEmployeeDialog(employee: employee);
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: Color(0xFF155084),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard(AppUser employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEAF3FA),
                child: Text(
                  _initials(employee.name),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF155084),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172B4D),
                      ),
                    ),
                    Text(
                      employee.email,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: const Color(0xFF7A8491),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showEmployeeDialog(employee: employee);
                },
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF155084)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _infoItem('Employee ID', employee.employeeId)),
              Expanded(child: _infoItem('Role', _roleName(employee.role))),
              _statusBadge(employee),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: const Color(0xFF7A8491),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF172B4D),
          ),
        ),
      ],
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FA),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _roleName(role),
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF155084),
        ),
      ),
    );
  }

  Widget _statusBadge(AppUser employee) {
    final active = employee.isActive && employee.accountStatus == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF7EE) : const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF35A853) : const Color(0xFFE53935),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No employees found',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF7A8491),
        ),
      ),
    );
  }

  String _roleName(String role) {
    switch (role) {
      case 'agent':
        return 'Agent';
      case 'team_lead':
        return 'Team Lead';
      case 'admin':
        return 'Area Manager';
      case 'super_admin':
        return 'Super Admin';
      default:
        return role;
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _showEmployeeDialog({AppUser? employee}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return EmployeeFormDialog(
          employee: employee,
          onSave: ({required AppUser employee}) async {
            debugPrint('SAVE BUTTON WORKING');
            debugPrint('Employee: ${employee.name}');
            debugPrint('Google Email: ${employee.email}');

            try {
              if (employee.uid.isEmpty) {
                debugPrint('CREATING EMPLOYEE...');

                await _employeeService.createEmployee(
                  employeeId: employee.employeeId,
                  name: employee.name,
                  email: employee.email,
                  role: employee.role,
                  designation: employee.designation,
                  isActive: employee.isActive,
                );
                debugPrint('EMPLOYEE CREATED SUCCESSFULLY');
              } else {
                debugPrint('UPDATING EMPLOYEE...');

                await _employeeService.updateEmployee(employee: employee);

                debugPrint('EMPLOYEE UPDATED SUCCESSFULLY');
              }
            } catch (e) {
              debugPrint('EMPLOYEE ERROR: $e');
              rethrow;
            }
          },
        );
      },
    );
  }
}
