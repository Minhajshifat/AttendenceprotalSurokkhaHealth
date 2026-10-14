import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardGreeting extends StatelessWidget {
  final String name;
  final String subtitle;

  const DashboardGreeting({
    super.key,
    required this.name,
    this.subtitle = 'Manage your attendance from here.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good day, $name',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF172B4D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
