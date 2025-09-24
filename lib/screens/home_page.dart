import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_button.dart';
import '../widgets/timer_modal.dart';
import '../services/ride_request_service.dart';
import 'activity_logs_screen.dart';
import 'account_settings_screen.dart';
import 'request_trike.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MainScreenContent(), // index 0 → Home
      const ActivityLogsScreen(), // index 1 → Activity Logs
      const AccountSettingsScreen(), // index 2 → Account Settings
    ];

    return Scaffold(
      body: Stack(
        children: [
          pages[selectedIndex],
          BottomNavigationBarWidget(
            selectedIndex: selectedIndex,
            onTap: (index) => setState(() => selectedIndex = index),
          ),
        ],
      ),
    );
  }
}

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  State<MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
  final Set<Marker> _markers = {};
  LatLng? _currentUserLocation;
  GoogleMapController? _mapController;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _loadTerminalMarkers();
    _getCurrentLocation();
  }

  /// Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
      });

      // Get address from coordinates (you might want to use geocoding)
      _currentAddress = "Current Location"; // Placeholder
      
      print('Current location: ${_currentUserLocation}');
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  /// Resize and load a custom marker
  Future<BitmapDescriptor> _getResizedMarker(String path, int targetWidth) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List resizedData =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.fromBytes(resizedData);
  }

  /// Load multiple terminal markers
  Future<void> _loadTerminalMarkers() async {
    final BitmapDescriptor terminalIcon =
        await _getResizedMarker('assets/icons/terminal.png', 120); // Size of icon

    // Location of 5 terminals
    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710), 
      const LatLng(15.117600, 120.614200), 
      const LatLng(15.118200, 120.617200), 
      const LatLng(15.115600, 120.613500), 
      const LatLng(15.115900, 120.616000), 
    ];

    setState(() {
      for (int i = 0; i < terminalLocations.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('terminal${i + 1}'),
            position: terminalLocations[i],
            icon: terminalIcon,
            infoWindow: InfoWindow(
              title: "Tricycle Terminal ${i + 1}",
              snippet: "Telabastagan",
            ),
          ),
        );
      }
    });
  }

  /// Handle ride request
  Future<void> _handleRideRequest() async {
    if (_currentUserLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your location. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to ride request page with user location
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestTrikePage(
          userLocation: _currentUserLocation!,
          userAddress: _currentAddress ?? "Unknown Address",
        ),
      ),
    );

    // Handle the result if needed
    if (result != null && result is RideRequest) {
      // Show success message or navigate to tracking screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // Safe top padding (status bar)
    final safeTop = MediaQuery.of(context).padding.top;

    final buttonWidth = w * 0.65;
    const buttonHeight = 60.0;

    /// Restrict movement inside Telabastagan vicinity
    final LatLngBounds telabastaganBounds = LatLngBounds(
      southwest: const LatLng(15.1140, 120.6125),
      northeast: const LatLng(15.1195, 120.6185),
    );

    return Stack(
      children: [
        /// Google Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(15.116888, 120.615710), // Telabastagan
            zoom: 16.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          cameraTargetBounds: CameraTargetBounds(telabastaganBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(16, 20),
          markers: _markers,
        ),

        /// Settings Button
        Positioned(
          top: safeTop + 16, // 16 pixels below the status bar
          right: w * 0.04,
          child: SettingsButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsButton(),
                ),
              );
            },
          ),
        ),

        /// Request Trike Button
        Positioned(
          bottom: h * 0.15,
          left: (w - buttonWidth) / 2,
          child: GestureDetector(
            onTap: _handleRideRequest,
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              decoration: ShapeDecoration(
                color: const Color(0xFF0097B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Request Trike',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}