import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'location_preview.dart';

class CheckInConfirmationDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double accuracy;
  final Future<void> Function(double latitude, double longitude) onViewMap;

  const CheckInConfirmationDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.onViewMap,
  });

  @override
  State<CheckInConfirmationDialog> createState() =>
      _CheckInConfirmationDialogState();
}

class _CheckInConfirmationDialogState extends State<CheckInConfirmationDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Confirm Attendance',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please confirm your attendance details.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            LocationPreview(
              latitude: widget.latitude,
              longitude: widget.longitude,
              accuracy: widget.accuracy,
              onViewMap: () {
                widget.onViewMap(widget.latitude, widget.longitude);
              },
            ),

            const SizedBox(height: 18),

            Text(
              'Note (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Add a short note...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF155084)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _noteController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF155084),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Confirm',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
