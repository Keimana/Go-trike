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
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      const MainScreenContent(),
      const ActivityLogsScreen(),
      const AccountSettingsScreen(),
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

enum LocationPickMode { none, pickup, destination }

class MainScreenContent extends StatefulWidget {
  const MainScreenContent({super.key});

  @override
  State<MainScreenContent> createState() => _MainScreenContentState();
}

class _MainScreenContentState extends State<MainScreenContent> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentUserLocation;
  LatLng? _selectedPickupLocation;
  LatLng? _selectedDestinationLocation;
  String? _currentAddress;
  String? _selectedPickupAddress;
  String? _selectedDestinationAddress;
  LocationPickMode _pickMode = LocationPickMode.none;
  bool _useCurrentLocation = true;

  BitmapDescriptor? _terminalIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destinationIcon;
  bool _iconsLoaded = false;

  static const List<LatLng> _terminalLocations = [
    LatLng(15.116888, 120.615710),
    LatLng(15.117600, 120.614200),
    LatLng(15.118200, 120.617200),
    LatLng(15.115600, 120.613500),
    LatLng(15.115900, 120.616000),
  ];

  bool _hasPendingRide = false;
  String? _activeRideId;
  StreamSubscription<RideRequest?>? _rideStatusSubscription;
  StreamSubscription<List<RideRequest>>? _userRidesSubscription;
  bool _hasShownAcceptedModal = false;

  String? _distanceText;
  String? _durationText;
  bool _isCalculatingRoute = false;

  static final LatLngBounds _telabastaganBounds = LatLngBounds(
    southwest: const LatLng(15.1140, 120.6125),
    northeast: const LatLng(15.1195, 120.6185),
  );

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadCustomMarkers(),
      _getCurrentLocation(),
    ]);
    
    if (mounted) {
      _loadTerminalMarkers();
      _checkForPendingRides();
    }
  }

  @override
  void dispose() {
    _rideStatusSubscription?.cancel();
    _userRidesSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {
    if (_iconsLoaded) return;

    try {
      final results = await Future.wait([
        _getResizedMarker('assets/icons/terminal.png', 120),
        _createCustomMarker(Colors.green),
        _createCustomMarker(Colors.red),
      ]);

      if (mounted) {
        _terminalIcon = results[0];
        _pickupIcon = results[1];
        _destinationIcon = results[2];
        _iconsLoaded = true;
      }
    } catch (e) {
      debugPrint('Error loading markers: $e');
      _terminalIcon = BitmapDescriptor.defaultMarker;
      _pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _iconsLoaded = true;
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(Color color) async {
    const int size = 150;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint paint = Paint()..color = color..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;

    canvas.drawCircle(const Offset(75, 60), 30, paint);
    canvas.drawCircle(const Offset(75, 60), 30, borderPaint);

    final Path pinPath = Path();
    pinPath.moveTo(75, 90);
    pinPath.lineTo(55, 60);
    pinPath.lineTo(95, 60);
    pinPath.close();
    canvas.drawPath(pinPath, paint);
    canvas.drawPath(pinPath, borderPaint);

    final Paint centerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(75, 60), 10, centerPaint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes != null) {
      return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(
        color == Colors.green ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
      );
    }
  }

  Future<BitmapDescriptor> _getResizedMarker(String path, int targetWidth) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: targetWidth);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List resizedData = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedData);
  }

  void _loadTerminalMarkers() {
    if (!_iconsLoaded || _terminalIcon == null) return;

    final newMarkers = <Marker>{};
    for (int i = 0; i < _terminalLocations.length; i++) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('terminal${i + 1}'),
          position: _terminalLocations[i],
          icon: _terminalIcon!,
          infoWindow: InfoWindow(title: "Tricycle Terminal ${i + 1}", snippet: "Telabastagan"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers..clear()..addAll(newMarkers);
      });
    }
  }

  void _updateMarkers() {
    if (!_iconsLoaded) return;

    final newMarkers = <Marker>{};

    for (int i = 0; i < _terminalLocations.length; i++) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('terminal${i + 1}'),
          position: _terminalLocations[i],
          icon: _terminalIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: "Tricycle Terminal ${i + 1}", snippet: "Telabastagan"),
        ),
      );
    }

    if (_selectedPickupLocation != null && !_useCurrentLocation && _pickupIcon != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: _selectedPickupLocation!,
          icon: _pickupIcon!,
          infoWindow: InfoWindow(
            title: "Pickup Location", 
            snippet: _selectedPickupAddress ?? "Tap to view details"
          ),
        ),
      );
    }

    if (_selectedDestinationLocation != null && _destinationIcon != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination_location'),
          position: _selectedDestinationLocation!,
          icon: _destinationIcon!,
          infoWindow: InfoWindow(
            title: "Destination", 
            snippet: _selectedDestinationAddress ?? "Tap to view details"
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers..clear()..addAll(newMarkers);
      });
    }
  }

  bool _isWithinBounds(LatLng location) {
    return location.latitude >= _telabastaganBounds.southwest.latitude &&
        location.latitude <= _telabastaganBounds.northeast.latitude &&
        location.longitude >= _telabastaganBounds.southwest.longitude &&
        location.longitude <= _telabastaganBounds.northeast.longitude;
  }

  Future<String?> _reverseGeocode(LatLng location) async {
    try {
      final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('Google Maps API key is missing');
        return null;
      }

      final String url = 'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${location.latitude},${location.longitude}&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      return null;
    }
  }

  String _createFallbackAddress(LatLng location) {
    final double lat = location.latitude;
    String area = "Telabastagan";
    
    if (lat > 15.117) {
      area = "North $area";
    } else if (lat < 15.116) {
      area = "South $area";
    }
    
    return "$area (${lat.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})";
  }

  Future<String> _getReadableAddress(LatLng location) async {
    try {
      final fullAddress = await _reverseGeocode(location);
      
      if (fullAddress == null) {
        return _createFallbackAddress(location);
      }

      final parts = fullAddress.split(',');
      
      if (parts.length >= 2) {
        if (fullAddress.toLowerCase().contains('telabastagan')) {
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].toLowerCase().contains('telabastagan')) {
              if (i > 0) {
                return '${parts[i-1].trim()}, ${parts[i].trim()}';
              } else {
                return parts[i].trim();
              }
            }
          }
        }
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
      
      return fullAddress;
    } catch (e) {
      debugPrint('Error getting readable address: $e');
      return _createFallbackAddress(location);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showLocationPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final LatLng currentLocation = LatLng(position.latitude, position.longitude);

      if (!_isWithinBounds(currentLocation)) {
        if (mounted) _showOutOfBoundsDialog();
        return;
      }

      if (mounted) {
        setState(() {
          _currentUserLocation = currentLocation;
          _currentAddress = "Getting address...";
        });
      }

      final address = await _getReadableAddress(currentLocation);
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _currentAddress = "Location unavailable";
        });
        _showLocationErrorDialog();
      }
    }
  }

  void _onMapTap(LatLng tappedLocation) async {
    if (_pickMode == LocationPickMode.none) return;

    if (!_isWithinBounds(tappedLocation)) {
      _showSnackBar('Please pick a location within the service area', Colors.red);
      return;
    }

    if (_pickMode == LocationPickMode.pickup) {
      setState(() {
        _selectedPickupAddress = "Getting address...";
      });
    } else if (_pickMode == LocationPickMode.destination) {
      setState(() {
        _selectedDestinationAddress = "Getting address...";
      });
    }

    final address = await _getReadableAddress(tappedLocation);

    if (mounted) {
      setState(() {
        if (_pickMode == LocationPickMode.pickup) {
          _selectedPickupLocation = tappedLocation;
          _selectedPickupAddress = address;
        } else if (_pickMode == LocationPickMode.destination) {
          _selectedDestinationLocation = tappedLocation;
          _selectedDestinationAddress = address;
        }
        _pickMode = LocationPickMode.none;
        _calculateDistanceAndETA();
      });

      _updateMarkers();
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(tappedLocation, 17.0));
      _showSnackBar('Location selected: $address', Colors.green);
    }
  }

  void _enableLocationPicking(LocationPickMode mode) {
    if (_hasPendingRide) {
      _showSnackBar('Cannot change locations while you have a pending ride request', Colors.orange);
      return;
    }

    setState(() {
      _pickMode = mode;
      if (mode == LocationPickMode.pickup) {
        _useCurrentLocation = false;
      }
    });

    final message = mode == LocationPickMode.pickup
        ? 'Tap on the map to pick your pickup location'
        : 'Tap on the map to pick your destination';

    _showSnackBar(message, mode == LocationPickMode.pickup ? Colors.green : Colors.red);
  }

  Future<void> _calculateDistanceAndETA() async {
    final pickup = _getPickupLocation();
    final destination = _selectedDestinationLocation;
    
    if (pickup == null || destination == null) {
      setState(() {
        _distanceText = null;
        _durationText = null;
      });
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final result = await _getDistanceAndDuration(pickup, destination);
      
      if (mounted && result != null) {
        setState(() {
          _distanceText = result['distance'];
          _durationText = result['duration'];
          _isCalculatingRoute = false;
        });
      } else {
        _calculateFallbackDistanceAndETA(pickup, destination);
      }
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      _calculateFallbackDistanceAndETA(pickup, destination);
    }
  }

  Future<Map<String, String>?> _getDistanceAndDuration(LatLng origin, LatLng destination) async {
    try {
      final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) return null;

      final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=${origin.latitude},${origin.longitude}&'
          'destinations=${destination.latitude},${destination.longitude}&'
          'mode=driving&units=metric&departure_time=now&traffic_model=best_guess&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return {
              'distance': element['distance']['text'],
              'duration': element['duration']['text'],
            };
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _calculateFallbackDistanceAndETA(LatLng pickup, LatLng destination) {
    final distanceInMeters = Geolocator.distanceBetween(
      pickup.latitude, pickup.longitude, destination.latitude, destination.longitude);
    final distanceInKm = distanceInMeters / 1000;
    final minutes = ((distanceInKm / 15.0) * 60).round();
    final adjustedMinutes = minutes < 5 ? 5 : minutes + 2;

    if (mounted) {
      setState(() {
        _distanceText = distanceInKm < 1 ? '${(distanceInKm * 1000).round()} m' : '${distanceInKm.toStringAsFixed(1)} km';
        _durationText = '$adjustedMinutes mins';
        _isCalculatingRoute = false;
      });
    }
  }

  Future<void> _checkForPendingRides() async {
    try {
      _userRidesSubscription?.cancel();
      final userRidesStream = RideRequestService.listenToUserRides();
      
      _userRidesSubscription = userRidesStream.listen((rides) {
        if (!mounted) return;
        final hasPending = rides.any((ride) => ride.status == RideStatus.pending);
        
        if (_hasPendingRide != hasPending) {
          setState(() {
            _hasPendingRide = hasPending;
            if (hasPending) {
              final pendingRide = rides.firstWhere((ride) => ride.status == RideStatus.pending);
              _activeRideId = pendingRide.id;
              if (_rideStatusSubscription == null) {
                _startListeningToRideStatus(pendingRide.id);
              }
            } else {
              _activeRideId = null;
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error checking rides: $e');
    }
  }

  void _startListeningToRideStatus(String rideId) {
    _activeRideId = rideId;
    _hasShownAcceptedModal = false;
    _rideStatusSubscription?.cancel();
    
    _rideStatusSubscription = RideRequestService.listenToRideStatus(rideId).listen((rideRequest) {
      if (rideRequest == null || !mounted) return;

      if (rideRequest.status == RideStatus.noDriverAvailable) {
        _handleNoDriverAvailable();
        return;
      }

      if (rideRequest.status == RideStatus.cancelled) {
        _handleRideCancelled();
        return;
      }

      if (rideRequest.status == RideStatus.accepted && !_hasShownAcceptedModal) {
        _handleRideAccepted(rideRequest);
        return;
      }

      final isPending = rideRequest.status == RideStatus.pending;
      if (_hasPendingRide != isPending && mounted) {
        setState(() {
          _hasPendingRide = isPending;
        });
      }
    });
  }

  void _handleNoDriverAvailable() {
    setState(() {
      _hasPendingRide = false;
      _activeRideId = null;
    });
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = null;
    _showNoDriverAvailableDialog();
  }

  void _handleRideCancelled() {
    setState(() {
      _hasPendingRide = false;
      _activeRideId = null;
    });
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = null;
    _showRideCancelledDialog();
  }

  void _handleRideAccepted(RideRequest rideRequest) {
    _hasShownAcceptedModal = true;
    setState(() {
      _hasPendingRide = false;
      _activeRideId = null;
    });
    showDriverOnWayModal(context, rideRequest.todaNumber ?? 'N/A');
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = null;
  }

  Future<void> _handleRideRequest() async {
    if (_hasPendingRide) {
      _showSnackBar('You already have a pending ride request', Colors.orange);
      return;
    }

    final pickupLocation = _getPickupLocation();
    if (pickupLocation == null) {
      _showSnackBar('Please select a pickup location first', Colors.red);
      return;
    }

    if (_selectedDestinationLocation == null) {
      _showSnackBar('Please select a destination', Colors.red);
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
                userLocation: pickupLocation,
                userAddress: _getPickupAddressText(),
                destinationLocation: _selectedDestinationLocation,
                destinationAddress: _getDestinationAddressText(),
                precalculatedDistance: _distanceText,
                precalculatedDuration: _durationText,
                onRequestConfirmed: () => Navigator.of(context).pop(),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _hasPendingRide = true;
        _activeRideId = result.id;
      });
      _startListeningToRideStatus(result.id);
    }
  }

  LatLng? _getPickupLocation() {
    return _useCurrentLocation ? _currentUserLocation : _selectedPickupLocation;
  }

  String _getPickupAddressText() {
    if (_useCurrentLocation) {
      return _currentAddress ?? "Current Location";
    } else {
      return _selectedPickupAddress ?? "Selected Pickup";
    }
  }

  String _getDestinationAddressText() {
    return _selectedDestinationAddress ?? "Selected Destination";
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app needs location permission. You can:\n\n1. Enable in settings\n2. Pick location manually'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableLocationPicking(LocationPickMode.pickup);
            },
            child: const Text('Pick Manually'),
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

  void _showOutOfBoundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Out of Service Area'),
        content: const Text('Your location is outside Telabastagan. Please pick a location on the map.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableLocationPicking(LocationPickMode.pickup);
            },
            child: const Text('Pick Location'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Get Location'),
        content: const Text('Unable to get your location. Please pick manually.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableLocationPicking(LocationPickMode.pickup);
            },
            child: const Text('Pick Location'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _getCurrentLocation();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showNoDriverAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('No Driver Available', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Sorry, no drivers available. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showRideCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Ride Cancelled', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Your ride has been cancelled. You can request another when ready.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final buttonWidth = size.width * 0.65;

    final hasPickup = _useCurrentLocation ? _currentUserLocation != null : _selectedPickupLocation != null;
    final hasDestination = _selectedDestinationLocation != null;
    final canRequestRide = hasPickup && hasDestination && !_hasPendingRide;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(15.116888, 120.615710), zoom: 16.0),
          onMapCreated: (controller) => _mapController = controller,
          onTap: _onMapTap,
          myLocationEnabled: _useCurrentLocation,
          myLocationButtonEnabled: false,
          cameraTargetBounds: CameraTargetBounds(_telabastaganBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(16, 20),
          markers: _markers,
        ),

        Positioned(
          top: safeTop + 16,
          left: size.width * 0.04,
          right: size.width * 0.04,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _hasPendingRide ? null : () => _enableLocationPicking(LocationPickMode.destination),
                  child: Opacity(
                    opacity: _hasPendingRide ? 0.5 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedDestinationLocation != null ? Colors.red.withOpacity(0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _pickMode == LocationPickMode.destination ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Destination', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                Text(
                                  _getDestinationAddressText(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDestinationLocation != null ? Colors.black : Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _selectedDestinationLocation != null ? Icons.check_circle : Icons.add_circle_outline,
                            size: 20,
                            color: _selectedDestinationLocation != null ? Colors.green : const Color(0xFF0097B2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_distanceText != null && _durationText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0097B2).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0097B2).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.straighten, color: Color(0xFF0097B2), size: 18),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Distance', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                                Text(_distanceText!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0097B2))),
                              ],
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF0097B2), size: 18),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ETA', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                                Text(_durationText!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0097B2))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (_isCalculatingRoute) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0097B2))),
                        ),
                        SizedBox(width: 10),
                        Text('Calculating route...', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        Positioned(
          top: safeTop + 16,
          right: size.width * 0.04,
          child: SettingsButton(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ),

        if (_pickMode != LocationPickMode.none)
          Positioned(
            bottom: size.height * 0.25,
            left: size.width * 0.04,
            right: size.width * 0.04,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _pickMode == LocationPickMode.pickup ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_pickMode == LocationPickMode.pickup ? Icons.location_searching : Icons.flag, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _pickMode == LocationPickMode.pickup ? 'Tap map to select pickup location' : 'Tap map to select destination',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: size.height * 0.15,
          left: (size.width - buttonWidth) / 2,
          child: GestureDetector(
            onTap: canRequestRide ? _handleRideRequest : null,
            child: Container(
              width: buttonWidth,
              height: 60.0,
              decoration: ShapeDecoration(
                color: canRequestRide ? const Color(0xFF0097B2) : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                shadows: canRequestRide ? [BoxShadow(color: const Color(0xFF0097B2).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _hasPendingRide ? "Pending Request..." : !hasPickup ? "Select Pickup" : !hasDestination ? "Select Destination" : "Request Trike",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}