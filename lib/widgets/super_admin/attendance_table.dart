import 'package:flutter/material.dart';

import 'attendance_row.dart';

class AttendanceTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  final Future<void> Function(String attendanceId) onApprove;
  final Future<void> Function(String attendanceId) onReject;

  final Future<void> Function(Map<String, dynamic> record) onReset;

  const AttendanceTable({
    super.key,
    required this.records,
    required this.onApprove,
    required this.onReject,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final tableWidth = screenWidth < 900 ? 1350.0 : screenWidth - 64;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: DataTable(
              columnSpacing: 36,
              horizontalMargin: 28,
              headingRowHeight: 60,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 72,
              dividerThickness: 1,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: [
                DataColumn(label: _header('EMPLOYEE ID')),
                DataColumn(label: _header('NAME')),
                DataColumn(label: _header('ROLE')),
                DataColumn(label: _header('CHECK-IN')),
                DataColumn(label: _header('TIMING')),
                DataColumn(label: _header('STATUS')),
                DataColumn(label: _header('REVIEWS')),
                DataColumn(label: _header('LOCATION')),
                DataColumn(label: _header('APPROVAL')),
                DataColumn(label: _header('ACTION')),
              ],

              rows: records.map<DataRow>((record) {
                final latitude = (record['latitude'] as num?)?.toDouble();

                final longitude = (record['longitude'] as num?)?.toDouble();

                return AttendanceRow.build(
                  context: context,

                  employeeId: record['employeeId']?.toString() ?? '-',

                  name: record['name']?.toString() ?? '-',

                  role: record['role']?.toString() ?? '-',

                  checkInTime: record['checkInTime'] as DateTime,

                  timingStatus: record['timingStatus']?.toString() ?? '',

                  attendanceStatus:
                      record['attendanceStatus']?.toString() ??
                      record['approvalStatus']?.toString() ??
                      'pending',

                  teamLeadReviewed: record['teamLeadReviewed'] == true,

                  areaManagerReviewed: record['areaManagerReviewed'] == true,

                  latitude: latitude,
                  longitude: longitude,

                  onApprove: () async {
                    await onApprove(record['attendanceId'].toString());
                  },

                  onReject: () async {
                    await onReject(record['attendanceId'].toString());
                  },

                  onReset: () async {
                    await onReset(record);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.4,
      ),
    );
  }
}
