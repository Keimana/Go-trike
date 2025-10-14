import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/ride_request_service.dart'; 
import '../widgets/primary_button.dart';
import '../widgets/terminal_request_trike_modal.dart';
import 'signin_screen_terminal.dart';

class TerminalHome extends StatefulWidget {
  final String terminalName;
  final String terminalId;

  const TerminalHome({
    super.key,
    this.terminalName = 'Terminal 1',
    this.terminalId = 'terminal_1',
  });

  @override
  State<TerminalHome> createState() => _TerminalHomeState();
}

class _TerminalHomeState extends State<TerminalHome> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Marker> _userMarkers = {}; // NEW: For user locations
  StreamSubscription<List<RideRequest>>? _rideRequestsSubscription;
  
  // NEW: Custom marker icons
  BitmapDescriptor? _terminalIcon;
  BitmapDescriptor? _userIcon;

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

  // NEW: Create custom user marker
  // NEW: Create custom green user marker (matches user home pin)
Future<BitmapDescriptor> _createUserMarker() async {
    const int size = 150;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Green pin
    final Paint paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // White border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Pin circle
    canvas.drawCircle(const Offset(75, 60), 30, paint);
    canvas.drawCircle(const Offset(75, 60), 30, borderPaint);

    // Pin point (triangle bottom)
    final Path pinPath = Path();
    pinPath.moveTo(75, 90);
    pinPath.lineTo(55, 60);
    pinPath.lineTo(95, 60);
    pinPath.close();
    canvas.drawPath(pinPath, paint);
    canvas.drawPath(pinPath, borderPaint);

    // Center dot
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


  void _updateTerminalMarkers() async {
    final List<LatLng> terminalLocations = [
      const LatLng(15.116888, 120.615710),
      const LatLng(15.117600, 120.614200),
      const LatLng(15.118200, 120.617200),
      const LatLng(15.115600, 120.613500),
      const LatLng(15.115900, 120.616000),
    ];

    _terminalIcon = await _getResizedMarker('assets/icons/terminal.png', 120);
    _userIcon = await _createUserMarker(); // Load user marker

    setState(() {
      _markers.clear();
      for (int i = 0; i < terminalLocations.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('terminal_${i + 1}'),
            position: terminalLocations[i],
            icon: _terminalIcon!,
            infoWindow: InfoWindow(
              title: "Tricycle Terminal ${i + 1}",
              snippet: "Telabastagan",
            ),
          ),
        );
      }
    });
  }

  // NEW: Listen to ride requests and add user markers
  void _listenToRideRequests() {
    _rideRequestsSubscription?.cancel();
    
    _rideRequestsSubscription = RideRequestService.listenToTerminalRides(widget.terminalId)
        .listen((rideRequests) {
      _updateUserMarkers(rideRequests);
    });
  }

  //Update user markers based on ride requests
  void _updateUserMarkers(List<RideRequest> rideRequests) {
    if (_userIcon == null) return;

    final Set<Marker> newUserMarkers = {};

    for (int i = 0; i < rideRequests.length; i++) {
      final ride = rideRequests[i];
      
      newUserMarkers.add(
        Marker(
          markerId: MarkerId('user_${ride.id}'),
          position: ride.userLocation,
          icon: _userIcon!,
          infoWindow: InfoWindow(
            title: "Passenger: ${ride.userName}",
            snippet: "Tap for details\nFare: ₱${ride.fareAmount.toStringAsFixed(2)}",
          ),
          onTap: () {
            _showPassengerDetails(ride);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _userMarkers.clear();
        _userMarkers.addAll(newUserMarkers);
      });
    }
  }

  //Show passenger details when marker is tapped
  void _showPassengerDetails(RideRequest ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Passenger: ${ride.userName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Fare: ₱${ride.fareAmount.toStringAsFixed(2)}"),
            Text("Payment: ${ride.paymentMethod}"),
            Text("Pickup: ${ride.userAddress}"),
            if (ride.destinationAddress.isNotEmpty)
              Text("Drop-off: ${ride.destinationAddress}"),
            if (ride.distance.isNotEmpty)
              Text("Distance: ${ride.distance}"),
            if (ride.estimatedTime.isNotEmpty)
              Text("ETA: ${ride.estimatedTime}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    _rideRequestsSubscription?.cancel();
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreenTerminal()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _updateTerminalMarkers();
    // Start listening after a short delay to ensure markers are loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _listenToRideRequests();
    });
  }

  @override
  void dispose() {
    _rideRequestsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLngBounds telabastaganBounds = LatLngBounds(
      southwest: const LatLng(15.1140, 120.6125),
      northeast: const LatLng(15.1195, 120.6185),
    );

    // COMBINE BOTH MARKER SETS
    final allMarkers = {..._markers, ..._userMarkers};

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(15.116888, 120.615710),
              zoom: 16.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            cameraTargetBounds: CameraTargetBounds(telabastaganBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(16, 20),
            zoomControlsEnabled: true,
            markers: allMarkers, // 
          ),

          //Legend for markers
          Positioned(
          top: 30, // 
          left: 20, // 
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, color: Color(0xFF0097B2), size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Map Legend",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0097B2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildLegendItem("Passengers (Green marker)", Colors.green),
              ],
            ),
          ),
        ),



          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0097B2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                      ),
                      onPressed: () => _logout(context),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0097B2).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      widget.terminalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: 208,
                  height: 61,
                  child: PrimaryButton(
                    text: "Ride Request",
                    icon: SvgPicture.asset(
                      "assets/icons/person_search.svg",
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => TerminalRequestTrikeModal(
                          terminalId: widget.terminalId,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Helper method for legend items
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}