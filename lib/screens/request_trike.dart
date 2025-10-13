import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ride_request_service.dart';

class RequestTrikePage extends StatefulWidget {
  final LatLng userLocation;
  final String userAddress;
  final LatLng? destinationLocation;  // NEW: Destination coordinates
  final String? destinationAddress;   // NEW: Destination address text

  /// Optional callback the parent can provide. Called after the user taps OK
  /// in the success dialog. Useful to start cooldown or close the bottom sheet.
  final VoidCallback? onRequestConfirmed;

  const RequestTrikePage({
    super.key,
    required this.userLocation,
    required this.userAddress,
    this.destinationLocation,
    this.destinationAddress,
    this.onRequestConfirmed,
  });

  @override
  State<RequestTrikePage> createState() => _RequestTrikePageState();
}

class _RequestTrikePageState extends State<RequestTrikePage> {
  String _selectedPaymentMethod = 'Cash';
  bool _isSubmitting = false;
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (snapshot.exists && snapshot.data()!.containsKey('name')) {
      setState(() {
        _userName = snapshot['name'];
      });
    }
  }

  /// Calculate estimated distance between pickup and destination (in km)
  double _calculateDistance() {
    if (widget.destinationLocation == null) return 0.0;
    
    // Simple distance calculation (Haversine formula would be more accurate)
    final lat1 = widget.userLocation.latitude;
    final lon1 = widget.userLocation.longitude;
    final lat2 = widget.destinationLocation!.latitude;
    final lon2 = widget.destinationLocation!.longitude;
    
    final dLat = (lat2 - lat1) * 111.32; // degrees to km (approximate)
    final dLon = (lon2 - lon1) * 111.32 * 0.9962; // adjust for latitude
    
    final distance = (dLat * dLat + dLon * dLon);
    return distance > 0 ? distance : 0.1; // minimum 100m
  }

  /// Calculate estimated fare based on distance
  double _calculateFare() {
    if (widget.destinationLocation == null) return 0.0;
    
    final distance = _calculateDistance();
    
    // Basic fare structure
    const double baseFare = 15.0; // 
    const double perKmRate = 10.0; // Rate per km
    
    final fare = baseFare + (distance * perKmRate);
    return fare;
  }

  Future<void> _submitRideRequest() async {
    // Validate destination
    if (widget.destinationLocation == null) {
      _showErrorSnackBar('Please select a destination first');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fare = _calculateFare();
      
      final RideRequest? rideRequest =
          await RideRequestService.submitRideRequest(
        userLocation: widget.userLocation,
        userName: _userName,
        userAddress: widget.userAddress,
        destinationLocation: widget.destinationLocation!, // Pass destination
        destinationAddress: widget.destinationAddress ?? "Selected Destination",
        fareAmount: fare,
        paymentMethod: _selectedPaymentMethod,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(RideRequest rideRequest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Ride Request Submitted!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Request ID', rideRequest.id, Icons.tag),
                const SizedBox(height: 12),
                _buildInfoRow('Terminal', rideRequest.assignedTerminal.name, Icons.local_taxi),
                const SizedBox(height: 12),
                _buildInfoRow('Distance', rideRequest.distance, Icons.straighten),
                const SizedBox(height: 12),
                _buildInfoRow('ETA', rideRequest.estimatedTime, Icons.access_time),
                const SizedBox(height: 12),
                _buildInfoRow('Fare', '₱${rideRequest.fareAmount.toStringAsFixed(2)}', Icons.payments),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please wait for a tricycle driver to accept your request.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(rideRequest); // Close bottom sheet with result
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0097B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0097B2)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasDestination = widget.destinationLocation != null;
    final estimatedFare = _calculateFare();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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

            // Fare estimation
            if (hasDestination)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0097B2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments, color: Color(0xFF0097B2), size: 24),
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
                        fontSize: 20,
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

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
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
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Request & Cancel buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isSubmitting || !hasDestination ? null : _submitRideRequest,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isSubmitting || !hasDestination
                            ? Colors.grey
                            : const Color(0xFF0097B2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: !_isSubmitting && hasDestination
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
                                hasDestination ? 'Request a Ride' : 'Select Destination',
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