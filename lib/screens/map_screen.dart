import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/recycling_centers.dart';
import '../screens/recycling_center_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  Position? _currentPosition;

  RecyclingCenter? _selectedCenter;
  double? _selectedDistance;

  bool _loadingLocation = false;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFEAF6EC);
  static const Color background = Color(0xFFF5F8F5);

  static const LatLng _lagunaCenter = LatLng(
    14.2000,
    121.3000,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _loadingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Please enable location services.');

        if (mounted) {
          setState(() {
            _loadingLocation = false;
          });
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission was denied.');

        if (mounted) {
          setState(() {
            _loadingLocation = false;
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. '
          'Enable it in Android settings.',
        );

        if (mounted) {
          setState(() {
            _loadingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
      });

      _showMessage('Unable to get your current location.');
    }
  }

  // ============================================================
  // FIND NEAREST CENTER
  // ============================================================

  Future<void> _findNearestCenter() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (_currentPosition == null) {
      _showMessage('Unable to determine your location.');
      return;
    }

    if (lagunaRecyclingCenters.isEmpty) {
      _showMessage('No recycling centers available.');
      return;
    }

    RecyclingCenter? nearest;
    double shortestDistance = double.infinity;

    for (final center in lagunaRecyclingCenters) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        center.latitude,
        center.longitude,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearest = center;
      }
    }

    if (nearest == null) return;
    if (!mounted) return;

    setState(() {
      _selectedCenter = nearest;
      _selectedDistance = shortestDistance;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(nearest.latitude, nearest.longitude),
        15,
      ),
    );
  }

  // ============================================================
  // SELECT CENTER
  // ============================================================

  void _selectCenter(RecyclingCenter center) {
    double? distance;

    if (_currentPosition != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        center.latitude,
        center.longitude,
      );
    }

    setState(() {
      _selectedCenter = center;
      _selectedDistance = distance;
    });
  }

  // ============================================================
  // DIRECTIONS
  // ============================================================

  Future<void> _getDirections(RecyclingCenter center) async {
    final destination =
        '${center.latitude},${center.longitude}';

    final Uri mapsUri;

    if (_currentPosition != null) {
      final origin =
          '${_currentPosition!.latitude},'
          '${_currentPosition!.longitude}';

      mapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving',
      );
    } else {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=$destination',
      );
    }

    try {
      final opened = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Could not open Google Maps.');
      }
    } catch (e) {
      _showMessage('Could not open Google Maps.');
    }
  }

  // ============================================================
  // FORMAT DISTANCE
  // ============================================================

  String _formatDistance(double? meters) {
    if (meters == null) return 'Distance unavailable';

    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    final kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km away';
  }

  // ============================================================
  // MARKERS
  // ============================================================

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // USER LOCATION MARKER
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // ALL CENTERS ARE NOW VERIFIED - USE GREEN MARKERS
    for (final center in lagunaRecyclingCenters) {
      markers.add(
        Marker(
          markerId: MarkerId('recycling_${center.name}'),
          position: LatLng(center.latitude, center.longitude),
          infoWindow: InfoWindow(
            title: center.name,
            snippet: center.municipality,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: () => _selectCenter(center),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // OPEN DETAIL SCREEN
  // ============================================================

  void _openDetailScreen(RecyclingCenter center) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecyclingCenterScreen(
          center: center,
          distance: _formatDistance(_selectedDistance),
        ),
      ),
    );
  }

  // ============================================================
  // CENTER CARD
  // ============================================================

  Widget _centerCard() {
    final center = _selectedCenter;

    if (center == null) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.recycling_rounded,
                    color: primaryGreen,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              center.municipality,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // CLOSE BUTTON
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedCenter = null;
                      _selectedDistance = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // VERIFIED BADGE + DISTANCE
            Row(
              children: [
                // VERIFIED BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: primaryGreen,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // DISTANCE
                Text(
                  _formatDistance(_selectedDistance),
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // ADDRESS
            _infoRow(Icons.location_on_outlined, center.address),

            const SizedBox(height: 8),

            // MATERIALS
            _infoRow(Icons.recycling_outlined, center.materials),

            const SizedBox(height: 8),

            // HOURS
            _infoRow(Icons.access_time_rounded, center.hours),

            const SizedBox(height: 15),

            // BUTTONS
            Row(
              children: [
                // DETAILS BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetailScreen(center),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // DIRECTIONS BUTTON
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _getDirections(center),
                    icon: const Icon(
                      Icons.directions_rounded,
                      size: 18,
                    ),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: Stack(
        children: [
          // GOOGLE MAP
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _lagunaCenter,
              zoom: 10,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildMarkers(),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          // ====================================================
          // TOP HEADER
          // ====================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.recycling_rounded,
                        color: primaryGreen,
                        size: 22,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Recycling Map',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // FIND NEAREST BUTTON
          // ====================================================

          Positioned(
            top: 82,
            left: 16,
            right: 16,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _loadingLocation ? null : _findNearestCenter,
                icon: _loadingLocation
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.near_me_rounded),
                label: Text(
                  _loadingLocation
                      ? 'Finding your location...'
                      : 'Find Nearest Recycling Center',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      primaryGreen.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 7,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // CURRENT LOCATION BUTTON
          // ====================================================

          Positioned(
            right: 16,
            bottom: _selectedCenter == null ? 25 : 380,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                elevation: 7,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _getCurrentLocation,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: primaryGreen,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // CENTER CARD
          // ====================================================

          _centerCard(),
        ],
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                  );
                },
              ),
              _bottomNavItem(
                icon: Icons.camera_alt_outlined,
                label: 'Scan',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanScreen(),
                    ),
                  );
                },
              ),
              _bottomNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              _bottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                selected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV ITEM
  // ============================================================

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primaryGreen.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 23,
                color: selected
                    ? primaryGreen
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? primaryGreen
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}