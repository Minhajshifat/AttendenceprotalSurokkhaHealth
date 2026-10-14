import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_user.dart';

class EmployeeFormDialog extends StatefulWidget {
  final AppUser? employee;
  final Future<void> Function({required AppUser employee}) onSave;

  const EmployeeFormDialog({super.key, this.employee, required this.onSave});

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _designationController;

  String _role = 'agent';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    _nameController = TextEditingController(text: employee?.name ?? '');

    _emailController = TextEditingController(text: employee?.email ?? '');

    _employeeIdController = TextEditingController(
      text: employee?.employeeId ?? '',
    );

    _designationController = TextEditingController(
      text: employee?.designation ?? '',
    );

    _role = employee?.role ?? 'agent';
    _isActive = employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final employee = AppUser(
        uid: widget.employee?.uid ?? '',
        employeeId: _employeeIdController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        designation: _designationController.text.trim(),
        teamId: widget.employee?.teamId ?? '',
        teamIds: widget.employee?.teamIds ?? const [],
        teamLeadId: widget.employee?.teamLeadId ?? '',
        adminId: widget.employee?.adminId ?? '',
        accountStatus: _isActive ? 'active' : 'inactive',
        isActive: _isActive,
      );

      await widget.onSave(employee: employee);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.poppins(fontSize: 11),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Edit Employee' : 'Add Employee',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF172B4D),
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter employee name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter email address';
                    }

                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _employeeIdController,
                  label: 'Employee ID',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter employee ID';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: _inputDecoration('Role'),
                  items: const [
                    DropdownMenuItem(value: 'agent', child: Text('Agent')),
                    DropdownMenuItem(
                      value: 'team_lead',
                      child: Text('Team Lead'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Area Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'office_employee',
                      child: Text('Office Employee'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _role = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _designationController,
                  label: 'Designation',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter employee designation';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Active Employee',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  value: _isActive,
                  activeThumbColor: const Color(0xFF155084),
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155084),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 11),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 11,
        color: const Color(0xFF687385),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
