import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_button.dart';
import 'activity_logs_screen.dart';
import 'account_settings_screen.dart';
import 'request_trike.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'settings_screen.dart';
import '../services/ride_request_service.dart';
import '../widgets/user_modal_accept.dart';


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

  // Pending ride tracking
  bool _hasPendingRide = false;
  String? _activeRideId;

  // Ride status listener variables
  StreamSubscription<RideRequest?>? _rideStatusSubscription;
  bool _hasShownAcceptedModal = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _loadTerminalMarkers();
    _getCurrentLocation();
    _checkForPendingRides();
  }

  @override
  void dispose() {
    _rideStatusSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Check if user has any pending rides
  Future<void> _checkForPendingRides() async {
    try {
      final userRidesStream = RideRequestService.listenToUserRides();
      
      userRidesStream.listen((rides) {
        if (!mounted) return;
        
        // Check if there's any pending ride
        final pendingRide = rides.firstWhere(
          (ride) => ride.status == RideStatus.pending,
          orElse: () => rides.first, // Fallback
        );
        
        final hasPending = rides.any((ride) => ride.status == RideStatus.pending);
        
        setState(() {
          _hasPendingRide = hasPending;
          if (hasPending) {
            _activeRideId = pendingRide.id;
            // Start listening to this ride if not already
            if (_rideStatusSubscription == null) {
              _startListeningToRideStatus(pendingRide.id);
            }
          } else {
            _activeRideId = null;
          }
        });
      });
    } catch (e) {
      print('Error checking for pending rides: $e');
    }
  }

  /// Show cancellation notification
  void _showRideCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Ride Cancelled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your ride request has been cancelled.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You can request another ride when you\'re ready.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear pending ride status
              setState(() {
                _hasPendingRide = false;
                _activeRideId = null;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Start listening to ride status
  void _startListeningToRideStatus(String rideId) {
    print('Started listening to ride: $rideId');
    _activeRideId = rideId;
    _hasShownAcceptedModal = false;
    
    // Cancel previous subscription if any
    _rideStatusSubscription?.cancel();
    
    // Start new subscription
    _rideStatusSubscription = RideRequestService.listenToRideStatus(rideId)
        .listen((rideRequest) {
      print('Ride status update received');
      print('Status: ${rideRequest?.status}');
      print('TODA Number: ${rideRequest?.todaNumber}');
      
      if (rideRequest == null || !mounted) return;

      // Update pending status based on ride status
      final isPending = rideRequest.status == RideStatus.pending;
      if (_hasPendingRide != isPending) {
        setState(() {
          _hasPendingRide = isPending;
        });
      }

      // Check if no driver available (FIRST - highest priority)
      if (rideRequest.status == RideStatus.noDriverAvailable) {
        print('No driver available');
        
        setState(() {
          _hasPendingRide = false;
          _activeRideId = null;
        });
        
        _showNoDriverAvailableDialog();
        
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
        return;
      }

      // Check if ride was cancelled (only show if it's a manual cancellation, not from cascade)
      if (rideRequest.status == RideStatus.cancelled) {
        print('Ride was cancelled');
        
        // Clear pending status
        setState(() {
          _hasPendingRide = false;
          _activeRideId = null;
        });
        
        // Only show cancellation dialog if it wasn't already handled as noDriverAvailable
        // This prevents showing "cancelled" after cascade exhaustion
        _showRideCancelledDialog();
        
        // Stop listening after showing dialog
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
        return;
      }

      // Check if ride was accepted and modal hasn't been shown yet
      if (rideRequest.status == RideStatus.accepted && 
          !_hasShownAcceptedModal) {
        _hasShownAcceptedModal = true;
        
        // Clear pending status
        setState(() {
          _hasPendingRide = false;
          _activeRideId = null;
        });
        
        // Get the TODA number
        final todaNumber = rideRequest.todaNumber ?? 'N/A';
        
        print('Showing driver modal with TODA: $todaNumber');
        
        // Show the "Driver is on your way" modal
        showDriverOnWayModal(context, todaNumber);
        
        // Stop listening after showing modal
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
      }
    }, onError: (error) {
      print('Error listening to ride status: $error');
    });
  }

  /// Show dialog when no driver is available
  void _showNoDriverAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'No Driver Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sorry, no drivers are available at the moment.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please try again later.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Load custom markers for terminals and pickup location
  Future<void> _loadCustomMarkers() async {
    try {
      _terminalIcon = await _getResizedMarker('assets/icons/terminal.png', 120);
    } catch (e) {
      _terminalIcon = BitmapDescriptor.defaultMarker;
    }
    // Use the more elaborate custom pickup marker for better visibility
    _pickupIcon = await _createCustomPickupMarker();
  }

  /// Alternative: Create a custom marker from scratch (more visible)
  Future<BitmapDescriptor> _createCustomPickupMarker() async {
    const int size = 150;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(const Offset(75, 60), 30, paint);
    canvas.drawCircle(const Offset(75, 60), 30, borderPaint);

    final Path pinPath = Path();
    pinPath.moveTo(75, 90);
    pinPath.lineTo(55, 60);
    pinPath.lineTo(95, 60);
    pinPath.close();
    canvas.drawPath(pinPath, paint);
    canvas.drawPath(pinPath, borderPaint);

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
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
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

      _currentAddress = "Current Location"; // Placeholder

    } catch (e) {
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
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Pick Location',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
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

    _updateMarkers();

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
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedData);
  }

  /// Load multiple terminal markers
  Future<void> _loadTerminalMarkers() async {
    if (_terminalIcon == null) {
      await _loadCustomMarkers();
    }

    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710),
      const LatLng(15.117600, 120.614200),
      const LatLng(15.118200, 120.617200),
      const LatLng(15.115600, 120.613500),
      const LatLng(15.115900, 120.616000),
    ];

    setState(() {
      _markers.clear();
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

    _updatePickupMarker();
  }

  /// Update markers (terminals + pickup location)
  void _updateMarkers() {
    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710),
      const LatLng(15.117600, 120.614200),
      const LatLng(15.118200, 120.617200),
      const LatLng(15.115600, 120.613500),
      const LatLng(15.115900, 120.616000),
    ];

    setState(() {
      _markers.clear();
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
      _updatePickupMarker();
    });
  }

  /// Update pickup location marker
  void _updatePickupMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'selected_location');

    if (_selectedLocation != null && !_useCurrentLocation) {
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: "Your Pickup Location",
            snippet: "Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}",
          ),
          onTap: () {
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

  Future<void> _handleRideRequest() async {
    // Check if there's already a pending ride
    if (_hasPendingRide) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a pending ride request'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final requestLocation = _getLocationForRequest();
    if (requestLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<RideRequest?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: RequestTrikePage(
                userLocation: requestLocation,
                userAddress: _getAddressText(),
                onRequestConfirmed: () {
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        );
      },
    );

    // Check if a ride was submitted (RequestTrikePage returns the RideRequest)
    if (result != null && result is RideRequest) {
      print('Ride request submitted with ID: ${result.id}');
      
      // Set pending ride status
      setState(() {
        _hasPendingRide = true;
        _activeRideId = result.id;
      });
      
      // Start listening to this ride's status
      _startListeningToRideStatus(result.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    final buttonWidth = w * 0.65;
    const buttonHeight = 60.0;

    // Restrict map inside Telabastagan vicinity
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
                    _updateMarkers();
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
          top: safeTop + 16,
          right: w * 0.04,
          child: SettingsButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
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

        /// Request Trike Button (disabled if pending ride exists)
        Positioned(
          bottom: h * 0.15,
          left: (w - buttonWidth) / 2,
          child: GestureDetector(
            onTap: _hasPendingRide ? null : _handleRideRequest,
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              decoration: ShapeDecoration(
                color: _hasPendingRide ? Colors.grey : const Color(0xFF0097B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _hasPendingRide ? "Pending Request..." : "Request Trike",
                style: const TextStyle(
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