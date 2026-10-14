import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_user.dart';
import '../../models/team_model.dart';

class TeamFormDialog extends StatefulWidget {
  final TeamModel? team;
  final List<AppUser> areaManagers;
  final List<AppUser> teamLeads;

  final Future<void> Function({
    required String name,
    required String areaManagerId,
    required String teamLeadId,
  })
  onSave;

  const TeamFormDialog({
    super.key,
    this.team,
    required this.areaManagers,
    required this.teamLeads,
    required this.onSave,
  });

  @override
  State<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  String? _areaManagerId;
  String? _teamLeadId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.team?.name ?? '');

    _areaManagerId = widget.team?.areaManagerId.isNotEmpty == true
        ? widget.team!.areaManagerId
        : null;

    _teamLeadId = widget.team?.teamLeadId.isNotEmpty == true
        ? widget.team!.teamLeadId
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_areaManagerId == null) {
      _showMessage('Please select an Area Manager');
      return;
    }

    if (_teamLeadId == null) {
      _showMessage('Please select a Team Lead');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(
        name: _nameController.text.trim(),
        areaManagerId: _areaManagerId!,
        teamLeadId: _teamLeadId!,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.team != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Edit Team' : 'Create Team',
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
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter team name';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(fontSize: 11),
                  decoration: _inputDecoration('Team Name'),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _areaManagerId,
                  isExpanded: true,
                  decoration: _inputDecoration('Area Manager'),
                  items: widget.areaManagers.map((manager) {
                    return DropdownMenuItem(
                      value: manager.uid,
                      child: Text(
                        manager.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _areaManagerId = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _teamLeadId,
                  isExpanded: true,
                  decoration: _inputDecoration('Team Lead'),
                  items: widget.teamLeads.map((lead) {
                    return DropdownMenuItem(
                      value: lead.uid,
                      child: Text(lead.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _teamLeadId = value;
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
