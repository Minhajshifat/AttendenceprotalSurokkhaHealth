import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../models/app_user.dart';
import '../../../../../../models/field_location_model.dart';
import '../../../../../../models/daily_team_location_model.dart';
import '../../../../../../services/field_location_service.dart';
import '../../../../../../services/daily_team_location_service.dart';
import '../../../../../../services/location_service.dart';

class FieldLocationScreen extends StatefulWidget {
  final AppUser user;

  const FieldLocationScreen({super.key, required this.user});

  @override
  State<FieldLocationScreen> createState() => _FieldLocationScreenState();
}

class _FieldLocationScreenState extends State<FieldLocationScreen> {
  final FieldLocationService _locationService = FieldLocationService();

  final DailyTeamLocationService _dailyService = DailyTeamLocationService();

  final LocationService _gpsService = LocationService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================================================
  // ROLE HELPERS
  // ==================================================

  String _normalizeRole(String role) {
    return role
        .toLowerCase()
        .trim()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }

  bool get _isSuperAdmin {
    return _normalizeRole(widget.user.role) == 'superadmin';
  }

  bool get _isAreaManager {
    return _normalizeRole(widget.user.role) == 'admin';
  }

  // ==================================================
  // BUILD
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
          'Field Locations',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
      ),

      // ==================================================
      // ADD LOCATION
      // ==================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF155084),
        foregroundColor: Colors.white,
        onPressed: _showAddLocationDialog,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(
          'Add Location',
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),

      body: StreamBuilder<List<FieldLocationModel>>(
        stream: _isSuperAdmin
            ? _locationService.getFieldLocations()
            : _locationService.getAreaManagerLocations(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessage(
              'Unable to load field locations.',
              Icons.error_outline_rounded,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF155084)),
            );
          }

          final locations = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(locations.length),

              const SizedBox(height: 20),

              // ==================================================
              // TEAM ASSIGNMENT SECTION
              // ==================================================
              _buildTeamAssignmentCard(),

              const SizedBox(height: 20),

              // ==================================================
              // LOCATION COLLECTION
              // ==================================================
              Text(
                'Location Collection',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'These locations are saved permanently and can be assigned to different teams.',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF7A8491),
                ),
              ),

              const SizedBox(height: 14),

              if (locations.isEmpty)
                _buildEmpty()
              else
                ...locations.map(
                  (location) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLocationCard(location),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  // ==================================================
  // HEADER
  // ==================================================

  Widget _buildHeader(int count) {
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
              Icons.location_on_outlined,
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
                  'Field Location Management',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$count location${count == 1 ? '' : 's'} in collection',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _isSuperAdmin ? 'Super Admin' : 'Area Manager',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
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

  // ==================================================
  // TEAM ASSIGNMENT CARD
  // ==================================================

  Widget _buildTeamAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFF155084),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Location to Team',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF172B4D),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Select a team and an existing location.',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: const Color(0xFF7A8491),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showTeamAssignmentDialog,
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: Text(
                'Assign Location',
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

  // ==================================================
  // LOCATION CARD
  // ==================================================

  Widget _buildLocationCard(FieldLocationModel location) {
    return FutureBuilder<List<DailyTeamLocationModel>>(
      future: _getTeamsUsingLocation(location.id),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: Column(
            children: [
              // ==================================================
              // TITLE
              // ==================================================
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF155084),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF172B4D),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          location.isActive
                              ? 'Active Location'
                              : 'Inactive Location',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: location.isActive
                                ? const Color(0xFF35A853)
                                : const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditLocationDialog(location);
                      }

                      if (value == 'delete') {
                        _confirmDelete(location);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Divider(height: 1, color: Color(0xFFECEFF3)),

              const SizedBox(height: 14),

              // ==================================================
              // LOCATION DETAILS
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      'Latitude',
                      location.latitude.toStringAsFixed(6),
                    ),
                  ),

                  Expanded(
                    child: _infoItem(
                      'Longitude',
                      location.longitude.toStringAsFixed(6),
                    ),
                  ),

                  Expanded(
                    child: _infoItem(
                      'Radius',
                      '${location.radiusMeters.toStringAsFixed(0)} m',
                    ),
                  ),
                ],
              ),

              // ==================================================
              // CURRENT TEAM
              // ==================================================
              if (assignments.isNotEmpty) ...[
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currently Assigned Team(s)',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: const Color(0xFF7A8491),
                        ),
                      ),

                      const SizedBox(height: 6),

                      ...assignments.map(
                        (assignment) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                size: 16,
                                color: Color(0xFF155084),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: FutureBuilder<String>(
                                  future: _getTeamName(assignment.teamId),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? 'Loading team...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF172B4D),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ==================================================
              // MAP
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _gpsService.openMap(location.latitude, location.longitude);
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    'View on Google Maps',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF155084),
                    side: const BorderSide(color: Color(0xFF155084)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================================================
  // GET TEAMS USING LOCATION
  // ==================================================

  Future<List<DailyTeamLocationModel>> _getTeamsUsingLocation(
    String locationId,
  ) async {
    final assignments = await _dailyService.getAllCurrentTeamLocations();

    return assignments
        .where((assignment) => assignment.locationId == locationId)
        .toList();
  }

  // ==================================================
  // GET TEAM NAME
  // ==================================================

  Future<String> _getTeamName(String teamId) async {
    if (teamId.trim().isEmpty) {
      return 'Unknown Team';
    }

    final doc = await _firestore.collection('teams').doc(teamId).get();

    if (!doc.exists || doc.data() == null) {
      return 'Unknown Team';
    }

    return doc.data()?['name']?.toString() ?? 'Unknown Team';
  }

  // ==================================================
  // GET TEAMS
  // ==================================================

  Future<List<Map<String, dynamic>>> _getTeams() async {
    final snapshot = await _firestore
        .collection('teams')
        .where('isActive', isEqualTo: true)
        .get();

    final teams = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'name': data['name']?.toString() ?? '',
        'areaManagerId': data['areaManagerId']?.toString() ?? '',
      };
    }).toList();

    // Area Manager sees only their teams.
    if (_isAreaManager) {
      teams.removeWhere(
        (team) => team['areaManagerId'].toString() != widget.user.uid,
      );
    }

    teams.sort(
      (a, b) => a['name'].toString().toLowerCase().compareTo(
        b['name'].toString().toLowerCase(),
      ),
    );

    return teams;
  }

  // ==================================================
  // SHOW TEAM ASSIGNMENT DIALOG
  // ==================================================
  Future<void> _showTeamAssignmentDialog() async {
    String? selectedTeamId;
    String? selectedLocationId;

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> assign() async {
              if (selectedTeamId == null || selectedTeamId!.trim().isEmpty) {
                _dialogError(dialogContext, 'Please select a team.');
                return;
              }

              if (selectedLocationId == null ||
                  selectedLocationId!.trim().isEmpty) {
                _dialogError(dialogContext, 'Please select a location.');
                return;
              }

              // Find selected location from Firestore list.
              final location = await _locationService.getFieldLocation(
                selectedLocationId!,
              );

              if (location == null) {
                _dialogError(dialogContext, 'Selected location was not found.');
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await _dailyService.assignLocationToTeam(
                  teamId: selectedTeamId!,
                  location: location,
                  assignedBy: widget.user.uid,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${location.name} assigned successfully.'),
                    ),
                  );

                  setState(() {});
                }
              } catch (e) {
                debugPrint('TEAM LOCATION ASSIGN ERROR: $e');

                if (context.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });
                }

                _dialogError(dialogContext, 'Unable to assign location.');
              }
            }

            return AlertDialog(
              title: Text(
                'Assign Location to Team',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ------------------------------------------
                      // TEAM
                      // ------------------------------------------
                      _buildTeamDropdown(
                        selectedTeamId: selectedTeamId,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTeamId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // ------------------------------------------
                      // LOCATION
                      // ------------------------------------------
                      _buildLocationDropdown(
                        selectedLocationId: selectedLocationId,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedLocationId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // ------------------------------------------
                      // SELECTED LOCATION INFO
                      // ------------------------------------------
                      if (selectedLocationId != null)
                        FutureBuilder<FieldLocationModel?>(
                          future: _locationService.getFieldLocation(
                            selectedLocationId!,
                          ),
                          builder: (context, snapshot) {
                            final location = snapshot.data;

                            if (location == null) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Location',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      color: const Color(0xFF7A8491),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    location.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF172B4D),
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    'Radius: ${location.radiusMeters.toStringAsFixed(0)} meters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: const Color(0xFF7A8491),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isSaving ? null : assign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155084),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isSaving ? 'Assigning...' : 'Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================================================
  // TEAM DROPDOWN
  // ==================================================

  Widget _buildTeamDropdown({
    required String? selectedTeamId,
    required ValueChanged<String?> onChanged,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Unable to load teams.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFFE53935),
            ),
          );
        }

        final teams = snapshot.data ?? [];

        final validTeamId = teams.any((team) => team['id'] == selectedTeamId)
            ? selectedTeamId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: validTeamId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Select Team',
            prefixIcon: const Icon(
              Icons.groups_outlined,
              color: Color(0xFF155084),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select Team'),
            ),
            ...teams.map(
              (team) => DropdownMenuItem<String>(
                value: team['id'] as String,
                child: Text(
                  team['name'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  // ==================================================
  // LOCATION DROPDOWN
  // ==================================================

  Widget _buildLocationDropdown({
    required String? selectedLocationId,
    required ValueChanged<String?> onChanged,
  }) {
    return StreamBuilder<List<FieldLocationModel>>(
      stream: _isSuperAdmin
          ? _locationService.getFieldLocations()
          : _locationService.getAreaManagerLocations(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Unable to load locations.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFFE53935),
            ),
          );
        }

        final locations = (snapshot.data ?? [])
            .where((location) => location.isActive)
            .toList();

        // Remove duplicate location IDs.
        final uniqueLocations = <String, FieldLocationModel>{};

        for (final location in locations) {
          uniqueLocations[location.id] = location;
        }

        final cleanLocations = uniqueLocations.values.toList();

        final validLocationId =
            cleanLocations.any((location) => location.id == selectedLocationId)
            ? selectedLocationId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: validLocationId,
          isExpanded: true,
          hint: const Text('Select Location'),
          decoration: InputDecoration(
            labelText: 'Select Existing Location',
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF155084),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: cleanLocations.map((location) {
            return DropdownMenuItem<String>(
              value: location.id,
              child: Text(
                '${location.name} (${location.radiusMeters.toStringAsFixed(0)}m)',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
  // ==================================================
  // ADD LOCATION
  // ==================================================

  Future<void> _showAddLocationDialog() async {
    await _showLocationDialog();
  }

  // ==================================================
  // EDIT LOCATION
  // ==================================================

  Future<void> _showEditLocationDialog(FieldLocationModel location) async {
    await _showLocationDialog(location: location);
  }

  // ==================================================
  // LOCATION CREATE / EDIT DIALOG
  // ==================================================

  Future<void> _showLocationDialog({FieldLocationModel? location}) async {
    final nameController = TextEditingController(text: location?.name ?? '');

    final latitudeController = TextEditingController(
      text: location?.latitude.toString() ?? '',
    );

    final longitudeController = TextEditingController(
      text: location?.longitude.toString() ?? '',
    );

    final radiusController = TextEditingController(
      text: location?.radiusMeters.toStringAsFixed(0) ?? '500',
    );

    bool isActive = location?.isActive ?? true;

    bool isGettingLocation = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> useCurrentLocation() async {
              setDialogState(() {
                isGettingLocation = true;
              });

              try {
                final position = await _gpsService.getCurrentLocation();

                latitudeController.text = position.latitude.toStringAsFixed(6);

                longitudeController.text = position.longitude.toStringAsFixed(
                  6,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to get location: $e')),
                  );
                }
              } finally {
                if (context.mounted) {
                  setDialogState(() {
                    isGettingLocation = false;
                  });
                }
              }
            }

            Future<void> save() async {
              final name = nameController.text.trim();

              final latitude = double.tryParse(latitudeController.text.trim());

              final longitude = double.tryParse(
                longitudeController.text.trim(),
              );

              final radius = double.tryParse(radiusController.text.trim());

              // ==================================================
              // VALIDATION
              // ==================================================

              if (name.isEmpty) {
                _dialogError(dialogContext, 'Please enter a location name.');
                return;
              }

              if (latitude == null || latitude < -90 || latitude > 90) {
                _dialogError(dialogContext, 'Please enter a valid latitude.');
                return;
              }

              if (longitude == null || longitude < -180 || longitude > 180) {
                _dialogError(dialogContext, 'Please enter a valid longitude.');
                return;
              }

              if (radius == null || radius <= 0) {
                _dialogError(dialogContext, 'Please enter a valid radius.');
                return;
              }

              // ==================================================
              // SAVE
              // ==================================================

              setDialogState(() {
                isSaving = true;
              });

              try {
                if (location == null) {
                  final areaManagerId = _isSuperAdmin ? '' : widget.user.uid;

                  await _locationService.createFieldLocation(
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    radiusMeters: radius,
                    areaManagerId: areaManagerId,
                  );
                } else {
                  final areaManagerId = _isSuperAdmin
                      ? location.areaManagerId
                      : widget.user.uid;

                  await _locationService.updateFieldLocation(
                    id: location.id,
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    radiusMeters: radius,
                    areaManagerId: areaManagerId,
                    isActive: isActive,
                  );
                }

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        location == null
                            ? 'Location added successfully.'
                            : 'Location updated successfully.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('LOCATION SAVE ERROR: $e');

                if (context.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });
                }

                _dialogError(dialogContext, 'Unable to save location.');
              }
            }

            return AlertDialog(
              title: Text(
                location == null ? 'Add Location' : 'Edit Location',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField(
                        controller: nameController,
                        label: 'Location Name',
                        hint: 'e.g. Mirpur 10',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 12),

                      _dialogField(
                        controller: latitudeController,
                        label: 'Latitude',
                        hint: 'e.g. 23.8069',
                        icon: Icons.explore_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _dialogField(
                        controller: longitudeController,
                        label: 'Longitude',
                        hint: 'e.g. 90.3687',
                        icon: Icons.explore_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _dialogField(
                        controller: radiusController,
                        label: 'Allowed Radius (meters)',
                        hint: '500',
                        icon: Icons.radar_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Example: 500 meters means the team can check in within 500 meters of this location.',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF7A8491),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isGettingLocation
                              ? null
                              : useCurrentLocation,
                          icon: isGettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 18),
                          label: Text(
                            isGettingLocation
                                ? 'Getting Location...'
                                : 'Use Current Location',
                          ),
                        ),
                      ),

                      if (location != null) ...[
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Active',
                            style: GoogleFonts.poppins(fontSize: 11),
                          ),
                          value: isActive,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155084),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    radiusController.dispose();
  }

  // ==================================================
  // DELETE LOCATION
  // ==================================================

  Future<void> _confirmDelete(FieldLocationModel location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Location?'),
          content: Text('Are you sure you want to delete "${location.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _locationService.deleteFieldLocation(location.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete location.')),
      );
    }
  }

  // ==================================================
  // DIALOG FIELD
  // ==================================================

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 11),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19, color: const Color(0xFF155084)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================================================
  // ERROR
  // ==================================================

  void _dialogError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
      ),
    );
  }

  // ==================================================
  // EMPTY
  // ==================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 50,
              color: Color(0xFF98A1AD),
            ),

            const SizedBox(height: 12),

            Text(
              'No field locations yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Add permanent locations such as Mirpur 10, Uttara, Gulshan, etc.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF7A8491),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // MESSAGE
  // ==================================================

  Widget _buildMessage(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: const Color(0xFFE53935)),

          const SizedBox(height: 10),

          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF687385),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // INFO ITEM
  // ==================================================

  Widget _infoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: const Color(0xFF7A8491),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF172B4D),
          ),
        ),
      ],
    );
  }
}
