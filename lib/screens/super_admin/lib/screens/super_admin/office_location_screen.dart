import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:surokkha_attendance/models/app_user.dart';
import 'package:surokkha_attendance/services/location_service.dart';

class OfficeLocationScreen extends StatefulWidget {
  final AppUser user;

  const OfficeLocationScreen({super.key, required this.user});

  @override
  State<OfficeLocationScreen> createState() => _OfficeLocationScreenState();
}

class _OfficeLocationScreenState extends State<OfficeLocationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: '1000',
  );

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfficeLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // ==================================================
  // LOAD OFFICE LOCATION
  // ==================================================

  Future<void> _loadOfficeLocation() async {
    try {
      final document = await _firestore
          .collection('office_settings')
          .doc('location')
          .get();

      if (!mounted) return;

      if (document.exists) {
        final data = document.data();

        _nameController.text = data?['name']?.toString() ?? '';
        _latitudeController.text = data?['latitude']?.toString() ?? '';
        _longitudeController.text = data?['longitude']?.toString() ?? '';
        _radiusController.text = data?['radiusMeters']?.toString() ?? '1000';
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('OFFICE LOCATION LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load office location.';
      });
    }
  }

  // ==================================================
  // GET CURRENT LOCATION
  // ==================================================

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);

        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      _showMessage('Current location detected successfully.');
    } catch (e) {
      debugPrint('OFFICE LOCATION GPS ERROR: $e');

      if (!mounted) return;

      _showMessage(_locationErrorMessage(e), isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  // ==================================================
  // SAVE OFFICE LOCATION
  // ==================================================

  Future<void> _saveOfficeLocation() async {
    final name = _nameController.text.trim();
    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();
    final radiusText = _radiusController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter the office name.', isError: true);
      return;
    }

    final latitude = double.tryParse(latitudeText);
    final longitude = double.tryParse(longitudeText);
    final radius = double.tryParse(radiusText);

    if (latitude == null || longitude == null) {
      _showMessage('Please enter valid latitude and longitude.', isError: true);
      return;
    }

    if (latitude < -90 || latitude > 90) {
      _showMessage('Latitude must be between -90 and 90.', isError: true);
      return;
    }

    if (longitude < -180 || longitude > 180) {
      _showMessage('Longitude must be between -180 and 180.', isError: true);
      return;
    }

    if (radius == null || radius <= 0) {
      _showMessage('Please enter a valid radius.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _firestore.collection('office_settings').doc('location').set({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radius,
        'updatedBy': widget.user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Office location saved successfully.');
    } catch (e) {
      debugPrint('OFFICE LOCATION SAVE ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to save office location.', isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
        title: Text(
          'Office Location',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF155084)),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF687385),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });

                _loadOfficeLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155084),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(),

        const SizedBox(height: 20),

        _buildLocationForm(),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF155084), Color(0xFF1B6A9E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fixed Office Location',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Set the location used for office attendance',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Office Location Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF172B4D),
            ),
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: _nameController,
            label: 'Office Name',
            hint: 'Enter office name',
            icon: Icons.business_outlined,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _latitudeController,
            label: 'Latitude',
            hint: 'e.g. 23.810331',
            icon: Icons.explore_outlined,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _longitudeController,
            label: 'Longitude',
            hint: 'e.g. 90.412521',
            icon: Icons.explore_outlined,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _radiusController,
            label: 'Allowed Radius (meters)',
            hint: 'e.g. 1000',
            icon: Icons.radar_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGettingLocation ? null : _useCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF155084),
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 19),
              label: Text(
                _isGettingLocation
                    ? 'Getting Current Location...'
                    : 'Use Current Location',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF155084),
                side: const BorderSide(color: Color(0xFF155084)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveOfficeLocation,
              icon: _isSaving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 19),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Office Location',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155084),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF172B4D)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19, color: const Color(0xFF155084)),
        labelStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: const Color(0xFF687385),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: const Color(0xFF98A1AD),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFCFE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF155084)),
        ),
      ),
    );
  }

  String _locationErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission')) {
      return 'Location permission is required. Please allow location access.';
    }

    if (message.contains('disabled')) {
      return 'Please enable location services and try again.';
    }

    return 'Unable to get your current location.';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF35A853),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 11)),
      ),
    );
  }
}
