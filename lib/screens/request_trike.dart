import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ride_request_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class RequestTrikePage extends StatefulWidget {
  final LatLng userLocation;
  final String userAddress;
  final LatLng? destinationLocation;
  final String? destinationAddress;
  final VoidCallback? onRequestConfirmed;
  
  final String? precalculatedDistance;
  final String? precalculatedDuration;

  const RequestTrikePage({
    super.key,
    required this.userLocation,
    required this.userAddress,
    this.destinationLocation,
    this.destinationAddress,
    this.onRequestConfirmed,
    this.precalculatedDistance,
    this.precalculatedDuration,
  });

  @override
  State<RequestTrikePage> createState() => _RequestTrikePageState();
}

class _RequestTrikePageState extends State<RequestTrikePage> {
  String _selectedPaymentMethod = 'Cash';
  bool _isSubmitting = false;
  bool _isLoadingRouteInfo = false;
  String _userName = "User";
  
  String? _distanceText;
  String? _durationText;
  double _distanceInKm = 0.0;
  int _durationInSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeRouteInfo();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (snapshot.exists && snapshot.data()!.containsKey('name')) {
      setState(() {
        _userName = snapshot['name'];
      });
    }
  }

  Future<void> _initializeRouteInfo() async {
    if (widget.destinationLocation == null) return;

    if (widget.precalculatedDistance != null && widget.precalculatedDuration != null) {
      setState(() {
        _distanceText = widget.precalculatedDistance;
        _durationText = widget.precalculatedDuration;
        _distanceInKm = _parseDistanceToKm(widget.precalculatedDistance!);
        _durationInSeconds = _parseDurationToSeconds(widget.precalculatedDuration!);
        _isLoadingRouteInfo = false;
      });
    } else {
      await _fetchRouteInformation();
    }
  }

  double _parseDistanceToKm(String distanceText) {
    try {
      final cleaned = distanceText.toLowerCase().replaceAll(',', '');
      if (cleaned.contains('km')) {
        return double.parse(cleaned.replaceAll('km', '').trim());
      } else if (cleaned.contains('m')) {
        final meters = double.parse(cleaned.replaceAll('m', '').trim());
        return meters / 1000.0;
      }
    } catch (e) {
      debugPrint('Error parsing distance: $e');
    }
    return 0.0;
  }

  int _parseDurationToSeconds(String durationText) {
    try {
      int totalSeconds = 0;
      final cleaned = durationText.toLowerCase();
      
      if (cleaned.contains('hour')) {
        final hourMatch = RegExp(r'(\d+)\s*hour').firstMatch(cleaned);
        if (hourMatch != null) {
          totalSeconds += int.parse(hourMatch.group(1)!) * 3600;
        }
      }
      
      if (cleaned.contains('min')) {
        final minMatch = RegExp(r'(\d+)\s*min').firstMatch(cleaned);
        if (minMatch != null) {
          totalSeconds += int.parse(minMatch.group(1)!) * 60;
        }
      }
      
      return totalSeconds > 0 ? totalSeconds : 300;
    } catch (e) {
      debugPrint('Error parsing duration: $e');
    }
    return 300;
  }

  Future<void> _fetchRouteInformation() async {
    if (widget.destinationLocation == null) return;

    setState(() {
      _isLoadingRouteInfo = true;
    });

    try {
      final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      
      if (apiKey.isEmpty) {
        print('API Key not found, using fallback calculation');
        _calculateFallbackRoute();
        return;
      }

      final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=${widget.userLocation.latitude},${widget.userLocation.longitude}&'
          'destinations=${widget.destinationLocation!.latitude},${widget.destinationLocation!.longitude}&'
          'mode=driving&'
          'units=metric&'
          'departure_time=now&'
          'traffic_model=best_guess&'
          'key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            setState(() {
              _distanceText = element['distance']['text'];
              _durationText = element['duration']['text'];
              _distanceInKm = element['distance']['value'] / 1000.0;
              _durationInSeconds = element['duration']['value'];
              _isLoadingRouteInfo = false;
            });
            return;
          }
        }
      }
      
      _calculateFallbackRoute();
      
    } catch (e) {
      print('Error fetching route info: $e');
      _calculateFallbackRoute();
    }
  }

  void _calculateFallbackRoute() {
    if (widget.destinationLocation == null) return;

    final distanceInMeters = Geolocator.distanceBetween(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
      widget.destinationLocation!.latitude,
      widget.destinationLocation!.longitude,
    );

    final distanceInKm = distanceInMeters / 1000.0;
    final estimatedMinutes = ((distanceInKm / 15.0) * 60).round();
    final adjustedMinutes = estimatedMinutes < 5 ? 5 : estimatedMinutes + 2;

    setState(() {
      _distanceInKm = distanceInKm;
      _durationInSeconds = adjustedMinutes * 60;
      _distanceText = distanceInKm < 1 
          ? '${(distanceInKm * 1000).round()} m' 
          : '${distanceInKm.toStringAsFixed(1)} km';
      _durationText = '$adjustedMinutes mins';
      _isLoadingRouteInfo = false;
    });
  }

  double _calculateFare() {
    if (widget.destinationLocation == null || _distanceInKm == 0) return 0.0;
    
    const double baseFare = 15.0;
    const double perKmRate = 10.0;
    
    final fare = baseFare + (_distanceInKm * perKmRate);
    return fare;
  }

  Future<void> _submitRideRequest() async {
    if (widget.destinationLocation == null) {
      _showErrorSnackBar('Please select a destination first');
      return;
    }

    if (_distanceText == null || _durationText == null) {
      _showErrorSnackBar('Loading route information, please wait...');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fare = _calculateFare();
      
      print('=== SUBMITTING RIDE REQUEST ===');
      print('Distance Text: $_distanceText');
      print('Duration Text: $_durationText');
      print('Distance in KM: $_distanceInKm');
      print('Duration in Seconds: $_durationInSeconds');
      print('Fare: $fare');
      print('===============================');
      
      final RideRequest? rideRequest = await RideRequestService.submitRideRequest(
        userLocation: widget.userLocation,
        userName: _userName,
        userAddress: widget.userAddress,
        destinationLocation: widget.destinationLocation!,
        destinationAddress: widget.destinationAddress ?? "Selected Destination",
        fareAmount: fare,
        paymentMethod: _selectedPaymentMethod,
        rideDistance: _distanceText!,
        rideEstimatedTime: _durationText!,
        rideDurationInSeconds: _durationInSeconds,
      );

      if (rideRequest != null) {
        if (mounted) _showSuccessDialog(rideRequest);
      } else {
        if (mounted) _showErrorSnackBar('Failed to submit ride request.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(RideRequest rideRequest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0097B2).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Request Submitted!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF323232),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactInfoCard(
                          'Request ID',
                          rideRequest.id,
                          Icons.tag,
                          Colors.purple,
                        ),
                        const SizedBox(height: 10),
                        _buildCompactInfoCard(
                          'Terminal',
                          rideRequest.assignedTerminal.name,
                          Icons.local_taxi,
                          Colors.blue,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactInfoCard(
                                'Distance',
                                rideRequest.distance,
                                Icons.straighten,
                                const Color(0xFF0097B2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactInfoCard(
                                'ETA',
                                rideRequest.estimatedTime,
                                Icons.access_time,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildFareCard(rideRequest.fareAmount),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please wait for a driver to accept your request.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(rideRequest); // Close bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0097B2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareCard(double fare) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0097B2),
            const Color(0xFF0097B2).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0097B2).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.payments, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Estimated Fare',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            '₱${fare.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDestination = widget.destinationLocation != null;
    final estimatedFare = _calculateFare();
    final isRouteInfoReady = _distanceText != null && _durationText != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Top center grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Ride Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF323232),
              ),
            ),
            const SizedBox(height: 20),

            // Pickup location card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Destination location card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasDestination 
                    ? Colors.red.withOpacity(0.05) 
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDestination 
                      ? Colors.red.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasDestination ? Colors.red : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.destinationAddress ?? 'No destination selected',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: hasDestination ? Colors.black87 : Colors.grey[400],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasDestination)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Route information
            if (hasDestination) ...[
              if (_isLoadingRouteInfo)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0097B2)),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Calculating route...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isRouteInfoReady)
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
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.straighten, color: Color(0xFF0097B2), size: 18),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distance',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _distanceText!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0097B2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF0097B2), size: 18),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ETA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _durationText!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0097B2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Fare estimation
            if (hasDestination && isRouteInfoReady)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0097B2).withOpacity(0.15),
                      const Color(0xFF0097B2).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0097B2).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments, color: Color(0xFF0097B2), size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Estimated Fare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF323232),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₱${estimatedFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0097B2),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Payment method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Cash';
                });
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == 'Cash'
                      ? const Color(0xFF0097B2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPaymentMethod == 'Cash'
                        ? const Color(0xFF0097B2)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.money,
                      color: _selectedPaymentMethod == 'Cash'
                          ? Colors.white
                          : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cash',
                      style: TextStyle(
                        color: _selectedPaymentMethod == 'Cash'
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Request & Cancel buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isSubmitting || !hasDestination || !isRouteInfoReady
                        ? null
                        : _submitRideRequest,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isSubmitting || !hasDestination || !isRouteInfoReady
                            ? Colors.grey
                            : const Color(0xFF0097B2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: !_isSubmitting && hasDestination && isRouteInfoReady
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0097B2).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                !hasDestination 
                                    ? 'Select Destination' 
                                    : _isLoadingRouteInfo 
                                        ? 'Loading...' 
                                        : 'Request a Ride',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFF0097B2), width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                              color: Color(0xFF0097B2),
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}