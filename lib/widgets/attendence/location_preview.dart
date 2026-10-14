import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double accuracy;
  final VoidCallback onViewMap;

  const LocationPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF43C047)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your current location has been detected.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF172B4D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewMap,
              icon: const Icon(Icons.map_outlined, size: 19),
              label: const Text('View My Location on Map'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'GPS accuracy: ${accuracy.toStringAsFixed(1)} meters',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
