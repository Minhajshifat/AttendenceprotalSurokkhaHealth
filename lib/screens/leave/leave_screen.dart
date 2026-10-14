import 'package:flutter/material.dart';
import '../../services/leave_service.dart';

class LeaveScreen extends StatefulWidget {
  final String userId;
  final String employeeId;
  final String employeeName;
  final String role;
  final String teamId;
  final String teamName;

  const LeaveScreen({
    super.key,
    required this.userId,
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveService _leaveService = LeaveService();

  String _selectedLeaveType = 'Casual Leave';

  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _reasonController = TextEditingController();

  bool _isSubmitting = false;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Annual Leave',
    'Emergency Leave',
    'Maternity/Paternity Leave',
    'Unpaid Leave',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) {
      return 0;
    }

    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _selectStartDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );

    if (selected == null) return;

    setState(() {
      _startDate = selected;

      if (_endDate != null && _endDate!.isBefore(selected)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the start date first.')),
      );
      return;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(
        _startDate!.year + 2,
        _startDate!.month,
        _startDate!.day,
      ),
    );

    if (selected == null) return;

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _submitLeaveRequest() async {
    if (_startDate == null || _endDate == null) {
      _showMessage('Please select start and end dates.');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showMessage('Please enter the reason for your leave.');
      return;
    }

    if (_totalDays <= 0) {
      _showMessage('Invalid leave duration.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _leaveService.createLeaveRequest(
        userId: widget.userId,
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        role: widget.role,
        teamId: widget.teamId,
        teamName: widget.teamName,
        leaveType: _selectedLeaveType,
        startDate: _startDate!,
        endDate: _endDate!,
        totalDays: _totalDays,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;

      _reasonController.clear();

      setState(() {
        _startDate = null;
        _endDate = null;
        _selectedLeaveType = 'Casual Leave';
      });

      _showMessage('Leave request submitted successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to submit leave request: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        title: const Text('Leave Request'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF155084),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply for Leave',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Submit your leave request for approval.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // LEAVE TYPE
            const Text(
              'Leave Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedLeaveType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _leaveTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedLeaveType = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // START DATE
            const Text(
              'Start Date',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            _dateButton(date: _startDate, onTap: _selectStartDate),

            const SizedBox(height: 20),

            // END DATE
            const Text(
              'End Date',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            _dateButton(date: _endDate, onTap: _selectEndDate),

            const SizedBox(height: 20),

            // TOTAL DAYS
            if (_totalDays > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total Leave Days: $_totalDays',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155084),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // REASON
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.w600)),

            const SizedBox(height: 8),

            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter the reason for your leave...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // SUBMIT
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLeaveRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF155084),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Leave Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton({required DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF155084)),

            const SizedBox(width: 12),

            Text(
              _formatDate(date),
              style: TextStyle(
                color: date == null ? Colors.grey : Colors.black87,
              ),
            ),

            const Spacer(),

            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
