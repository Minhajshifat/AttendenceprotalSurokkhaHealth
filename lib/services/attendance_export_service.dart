import 'dart:typed_data';

import 'package:excel/excel.dart';

class AttendanceExportService {
  static Future<Uint8List> generateExcel({
    required List<Map<String, dynamic>> records,
  }) async {
    final excel = Excel.createExcel();

    final sheet = excel['Attendance'];

    excel.delete('Sheet1');

    // =========================
    // HEADER
    // =========================

    sheet.appendRow([
      TextCellValue('Employee Name'),
      TextCellValue('Role'),
      TextCellValue('Employee ID'),
      TextCellValue('Team Name'),

      TextCellValue('Date'),
      TextCellValue('Check-in Time'),
      TextCellValue('Timing Status'),
      TextCellValue('Attendance Status'),
    ]);

    // =========================
    // DATA
    // =========================

    for (final record in records) {
      final checkInTime = record['checkInTime'];

      sheet.appendRow([
        TextCellValue(record['name']?.toString() ?? 'Unknown'),

        TextCellValue(_roleLabel(record['role']?.toString() ?? '')),

        TextCellValue(record['employeeId']?.toString() ?? '—'),

        TextCellValue(record['teamName']?.toString() ?? '—'),

        TextCellValue(record['date']?.toString() ?? '—'),

        TextCellValue(_formatTime(checkInTime)),

        TextCellValue(_timingLabel(record['timingStatus']?.toString() ?? '')),

        TextCellValue(
          _statusLabel(
            record['attendanceStatus']?.toString() ??
                record['status']?.toString() ??
                'missing',
          ),
        ),
      ]);
    }

    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Unable to generate Excel file');
    }

    return Uint8List.fromList(bytes);
  }

  static String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'area_manager':
        return 'Area Manager';

      case 'team_lead':
        return 'Team Lead';

      case 'agent':
        return 'Agent';

      default:
        return role;
    }
  }

  static String _timingLabel(String status) {
    switch (status.toLowerCase()) {
      case 'on_time':
        return 'On Time';

      case 'late':
        return 'Late';

      default:
        return '—';
    }
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'missing':
        return 'Missing';

      default:
        return 'Pending';
    }
  }

  static String _formatTime(dynamic value) {
    if (value == null) {
      return '—';
    }

    try {
      final dateTime = value is DateTime ? value : value.toDate();

      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;

      final minute = dateTime.minute.toString().padLeft(2, '0');

      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return '—';
    }
  }

  static Future<Uint8List> generateMonthlyExcel({
    required DateTime month,
    required List<Map<String, dynamic>> records,
  }) async {
    final excel = Excel.createExcel();

    final sheet = excel['Monthly Attendance'];

    excel.delete('Sheet1');

    // =========================
    // HEADER
    // =========================

    sheet.appendRow([
      TextCellValue('Employee Name'),
      TextCellValue('Role'),
      TextCellValue('Employee ID'),
      TextCellValue('Team Name'),

      TextCellValue('Date'),
      TextCellValue('Check-in Time'),
      TextCellValue('Timing Status'),
      TextCellValue('Attendance Status'),
    ]);

    // =========================
    // DATA
    // =========================

    for (final record in records) {
      final checkInTime = record['checkInTime'];

      sheet.appendRow([
        TextCellValue(record['name']?.toString() ?? 'Unknown'),

        TextCellValue(_roleLabel(record['role']?.toString() ?? '')),

        TextCellValue(record['employeeId']?.toString() ?? '—'),

        TextCellValue(record['teamName']?.toString() ?? '—'),

        TextCellValue(record['date']?.toString() ?? '—'),

        TextCellValue(_formatTime(checkInTime)),

        TextCellValue(_timingLabel(record['timingStatus']?.toString() ?? '')),

        TextCellValue(
          _statusLabel(
            record['attendanceStatus']?.toString() ??
                record['status']?.toString() ??
                'missing',
          ),
        ),
      ]);
    }

    // =========================
    // GENERATE EXCEL
    // =========================

    final bytes = excel.encode();

    if (bytes == null) {
      throw Exception('Unable to generate monthly Excel file');
    }

    return Uint8List.fromList(bytes);
  }
}
