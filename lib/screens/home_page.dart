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
  LatLng? _selectedLocation; // For manual location picking
  GoogleMapController? _mapController;
  String? _currentAddress;
  bool _isPickingLocation = false;
  bool _useCurrentLocation = true; // Toggle between current location and manual pick
  BitmapDescriptor? _terminalIcon;
  BitmapDescriptor? _pickupIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _loadTerminalMarkers();
    _getCurrentLocation();
  }

  /// Load custom markers for terminals and pickup location
  Future<void> _loadCustomMarkers() async {
    _terminalIcon = await _getResizedMarker('assets/icons/terminal.png', 120);
    // Use the more elaborate custom pickup marker for better visibility
    _pickupIcon = await _createCustomPickupMarker();
  }

  /// Create a custom pickup location marker
  Future<BitmapDescriptor> _createPickupMarker() async {
    // You can replace this with a custom icon from assets like:
    // return await _getResizedMarker('assets/icons/pickup_pin.png', 100);
    
    // For now, create a more visible marker
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  /// Alternative: Create a custom marker from scratch (more visible)
  Future<BitmapDescriptor> _createCustomPickupMarker() async {
    // This creates a custom colored marker - you can customize this further
    const int size = 150;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Draw a custom pin shape
    final Paint paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Draw the main pin shape
    canvas.drawCircle(const Offset(75, 60), 30, paint);
    canvas.drawCircle(const Offset(75, 60), 30, borderPaint);
    
    // Draw the pin point
    final Path pinPath = Path();
    pinPath.moveTo(75, 90);
    pinPath.lineTo(55, 60);
    pinPath.lineTo(95, 60);
    pinPath.close();
    canvas.drawPath(pinPath, paint);
    canvas.drawPath(pinPath, borderPaint);
    
    // Add a center dot
    final Paint centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(75, 60), 10, centerPaint);
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (bytes != null) {
      return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
    } else {
      // Fallback to default marker
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  /// Check if a location is within Telabastagan boundaries
  bool _isWithinBounds(LatLng location) {
    const double minLat = 15.1140;
    const double maxLat = 15.1195;
    const double minLng = 120.6125;
    const double maxLng = 120.6185;
    
    return location.latitude >= minLat && 
           location.latitude <= maxLat &&
           location.longitude >= minLng && 
           location.longitude <= maxLng;
  }

  /// Get user's current location
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        _showLocationPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng currentLocation = LatLng(position.latitude, position.longitude);

      // Check if current location is within bounds
      if (!_isWithinBounds(currentLocation)) {
        _showOutOfBoundsDialog();
        return;
      }

      setState(() {
        _currentUserLocation = currentLocation;
      });

      // Get address from coordinates (you might want to use geocoding)
      _currentAddress = "Current Location"; // Placeholder
      
      print('Current location: ${_currentUserLocation}');
    } catch (e) {
      print('Error getting location: $e');
      _showLocationErrorDialog();
    }
  }

  /// Show dialog when location permissions are denied
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to find the nearest terminal. You can either:\n\n'
          '1. Enable location permissions in settings\n'
          '2. Manually pick your location on the map',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableLocationPicking();
            },
            child: const Text('Pick Location Manually'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when current location is out of bounds
  void _showOutOfBoundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Out of Service Area'),
        content: const Text(
          'Your current location is outside our service area (Telabastagan). Please pick a location within the service area on the map.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableLocationPicking();
            },
            child: const Text('Pick Location'),
          ),
        ],
      ),
    );
  }

  /// Show dialog for location errors
  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Get Location'),
        content: const Text(
          'Unable to get your current location. Please pick your location manually on the map.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableLocationPicking();
            },
            child: const Text('Pick Location'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _getCurrentLocation(); // Try again
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Enable location picking mode
  void _enableLocationPicking() {
    setState(() {
      _isPickingLocation = true;
      _useCurrentLocation = false;
    });
    
    // Update markers to show/hide pickup marker
    _updateMarkers();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap on the map to pick your location'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Handle map tap for location picking
  void _onMapTap(LatLng tappedLocation) {
    if (!_isPickingLocation) return;

    if (!_isWithinBounds(tappedLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a location within the service area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = tappedLocation;
      _isPickingLocation = false;
    });

    // Refresh markers to show the selected location
    _updateMarkers();

    // Move camera to the selected location for better visibility
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(tappedLocation, 17.0),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Location selected! Ready to request ride.'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get the location to use for ride request
  LatLng? _getLocationForRequest() {
    if (_useCurrentLocation) {
      return _currentUserLocation;
    } else {
      return _selectedLocation;
    }
  }

  /// Get address text for display
  String _getAddressText() {
    if (_useCurrentLocation) {
      return _currentAddress ?? "Current Location";
    } else {
      return _selectedLocation != null ? "Selected Location" : "No location selected";
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
    // Wait for custom markers to load if they haven't already
    if (_terminalIcon == null) {
      await _loadCustomMarkers();
    }

    // Location of 5 terminals
    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710), 
      const LatLng(15.117600, 120.614200), 
      const LatLng(15.118200, 120.617200), 
      const LatLng(15.115600, 120.613500), 
      const LatLng(15.115900, 120.616000), 
    ];

    setState(() {
      _markers.clear();
      // Add terminal markers
      for (int i = 0; i < terminalLocations.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('terminal${i + 1}'),
            position: terminalLocations[i],
            icon: _terminalIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: "Tricycle Terminal ${i + 1}",
              snippet: "Telabastagan",
            ),
          ),
        );
      }
    });

    // Add pickup location marker if exists
    _updatePickupMarker();
  }

  /// Update markers (terminals + pickup location)
  void _updateMarkers() {
    // Location of 5 terminals
    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710), 
      const LatLng(15.117600, 120.614200), 
      const LatLng(15.118200, 120.617200), 
      const LatLng(15.115600, 120.613500), 
      const LatLng(15.115900, 120.616000), 
    ];

    setState(() {
      _markers.clear();
      
      // Add terminal markers
      for (int i = 0; i < terminalLocations.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('terminal${i + 1}'),
            position: terminalLocations[i],
            icon: _terminalIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: "Tricycle Terminal ${i + 1}",
              snippet: "Telabastagan",
            ),
          ),
        );
      }
      
      // Add pickup location marker
      _updatePickupMarker();
    });
  }

  /// Update pickup location marker
  void _updatePickupMarker() {
    // Remove existing pickup marker
    _markers.removeWhere((marker) => marker.markerId.value == 'selected_location');
    
    // Add selected location marker if exists and not using current location
    if (_selectedLocation != null && !_useCurrentLocation) {
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: "📍 Your Pickup Location",
            snippet: "Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}",
          ),
          onTap: () {
            // Optional: Show detailed info when marker is tapped
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Pickup Location'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 4),
                    Text('Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 12),
                    const Text(
                      'This is where your tricycle will pick you up.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _enableLocationPicking();
                    },
                    child: const Text('Change Location'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  /// Handle ride request
  Future<void> _handleRideRequest() async {
    final LatLng? requestLocation = _getLocationForRequest();
    
    if (requestLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first.'),
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
          userLocation: requestLocation,
          userAddress: _getAddressText(),
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
          onTap: _onMapTap,
          myLocationEnabled: _useCurrentLocation,
          myLocationButtonEnabled: _useCurrentLocation,
          cameraTargetBounds: CameraTargetBounds(telabastaganBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(16, 20),
          markers: _markers,
        ),

        /// Location Toggle Button
        Positioned(
          top: safeTop + 16,
          left: w * 0.04,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Location Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _useCurrentLocation = true;
                      _isPickingLocation = false;
                    });
                    _updateMarkers(); // Refresh markers
                    _getCurrentLocation();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _useCurrentLocation ? const Color(0xFF0097B2) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: _useCurrentLocation ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                // Pick Location Button
                GestureDetector(
                  onTap: _enableLocationPicking,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_useCurrentLocation ? const Color(0xFF0097B2) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.location_searching,
                      color: !_useCurrentLocation ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

        /// Location Status Indicator
        if (_isPickingLocation)
          Positioned(
            top: safeTop + 80,
            left: w * 0.04,
            right: w * 0.04,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap on the map to select your pickup location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
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