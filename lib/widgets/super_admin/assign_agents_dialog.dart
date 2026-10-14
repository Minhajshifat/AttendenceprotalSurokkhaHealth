import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_user.dart';
import '../../models/team_model.dart';

class AssignAgentsDialog extends StatefulWidget {
  final TeamModel team;
  final List<AppUser> agents;
  final List<String> selectedAgentIds;

  final Future<void> Function(List<String> agentIds) onSave;

  const AssignAgentsDialog({
    super.key,
    required this.team,
    required this.agents,
    required this.selectedAgentIds,
    required this.onSave,
  });

  @override
  State<AssignAgentsDialog> createState() => _AssignAgentsDialogState();
}

class _AssignAgentsDialogState extends State<AssignAgentsDialog> {
  late final Set<String> _selectedAgentIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _selectedAgentIds = widget.selectedAgentIds.toSet();
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(_selectedAgentIds.toList());

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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Assign Agents',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF172B4D),
        ),
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.team.name,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF7A8491),
              ),
            ),

            const SizedBox(height: 12),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.agents.length,
                itemBuilder: (context, index) {
                  final agent = widget.agents[index];

                  final isSelected = _selectedAgentIds.contains(agent.uid);

                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: const Color(0xFF155084),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      agent.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      agent.employeeId,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7A8491),
                      ),
                    ),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedAgentIds.add(agent.uid);
                              } else {
                                _selectedAgentIds.remove(agent.uid);
                              }
                            });
                          },
                  );
                },
              ),
            ),
          ],
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
              : const Text('Save Assignment'),
        ),
      ],
    );
  }
}
