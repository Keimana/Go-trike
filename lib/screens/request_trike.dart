import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ride_request_service.dart';

class RequestTrikePage extends StatefulWidget {
  final LatLng userLocation;
  final String userAddress;

  /// Optional callback the parent can provide. Called after the user taps OK
  /// in the success dialog. Useful to start cooldown or close the bottom sheet.
  final VoidCallback? onRequestConfirmed;

  const RequestTrikePage({
    super.key,
    required this.userLocation,
    required this.userAddress,
    this.onRequestConfirmed,
  });

  @override
  State<RequestTrikePage> createState() => _RequestTrikePageState();
}

class _RequestTrikePageState extends State<RequestTrikePage> {
  String _selectedPaymentMethod = 'Cash';
  bool _isSubmitting = false;
  String _userName = "User";
  String _destinationLocation = "Not Selected";

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

  Future<void> _submitRideRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final RideRequest? rideRequest =
          await RideRequestService.submitRideRequest(
        userLocation: widget.userLocation,
        userName: _userName,
        userAddress: widget.userAddress,
        fareAmount: 0,
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
          title: const Text('Ride Request Submitted!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Req ID:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(rideRequest.id),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Assigned Terminal:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(rideRequest.assignedTerminal.name),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Distance:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(rideRequest.distance),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('ETA:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(rideRequest.estimatedTime),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Fare:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('₱${rideRequest.fareAmount.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please wait for a tricycle driver to accept your request.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 255, 94, 0),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the success dialog first
                Navigator.of(context).pop();

                // If parent provided a callback, call it. Parent will handle closing
                // the bottom sheet and starting cooldown.
                if (widget.onRequestConfirmed != null) {
                  widget.onRequestConfirmed!();
                } else {
                  // Fallback: close the bottom sheet and return the rideRequest
                  Navigator.of(context).pop(rideRequest);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0097B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // keyboard safe
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Top center grabber
            Center(
              child: Container(
                width: 40, // width of the bar
                height: 4, // thickness
                decoration: BoxDecoration(
                  color: Colors.grey[400], // grey color
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pickup location
            Text(
              widget.userAddress,
              style: const TextStyle(
                color: Color(0xFF323232),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),

            // Destination picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Destination: $_destinationLocation",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _destinationLocation = "Sample Destination"; // dito ka mag lagay ng entity for destination point (drop off location)
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Choose Location",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Payment method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Cash';
                });
              },
              child: Container(
                width: screenWidth * 0.25,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedPaymentMethod == 'Cash'
                      ? const Color(0xFF0097B2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Cash',
                    style: TextStyle(
                      color: _selectedPaymentMethod == 'Cash'
                          ? Colors.white
                          : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Request & Cancel buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : _submitRideRequest,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isSubmitting
                            ? Colors.grey
                            : const Color(0xFF0097B2),
                        borderRadius: BorderRadius.circular(30),
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
                            : const Text(
                                'Request a Ride',
                                style: TextStyle(
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
                            color: const Color(0xFF0097B2), width: 1),
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
          ],
        ),
      ),
    );
  }
}
