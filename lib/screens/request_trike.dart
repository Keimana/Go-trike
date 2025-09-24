import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ added
import '../services/ride_request_service.dart';

class RequestTrikePage extends StatefulWidget {
  final LatLng userLocation;
  final String userAddress;

  const RequestTrikePage({
    super.key,
    required this.userLocation,
    required this.userAddress,
  });

  @override
  State<RequestTrikePage> createState() => _RequestTrikePageState();
}

class _RequestTrikePageState extends State<RequestTrikePage> {
  final TextEditingController _fareController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  bool _isSubmitting = false;
  String _userName = "User"; // ✅ store Firestore name here

  @override
  void initState() {
    super.initState();
    _loadUserName();
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

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _submitRideRequest() async {
    if (_fareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter fare amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double? fareAmount = double.tryParse(_fareController.text);
    if (fareAmount == null || fareAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid fare amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('Submitting ride request...');
      print('User Name: $_userName');
      print('User Location: ${widget.userLocation}');
      print('User Address: ${widget.userAddress}');
      print('Fare Amount: $fareAmount');
      print('Payment Method: $_selectedPaymentMethod');

      final RideRequest? rideRequest = await RideRequestService.submitRideRequest(
        userLocation: widget.userLocation,
        userName: _userName, // ✅ Firestore name
        userAddress: widget.userAddress,
        fareAmount: fareAmount,
        paymentMethod: _selectedPaymentMethod,
      );

      if (rideRequest != null) {
        if (mounted) {
          _showSuccessDialog(rideRequest);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit ride request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting ride request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(RideRequest rideRequest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ride Request Submitted!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request ID: ${rideRequest.id}'),
              const SizedBox(height: 8),
              Text('Assigned Terminal: ${rideRequest.assignedTerminal.name}'),
              const SizedBox(height: 8),
              Text('Distance: ${rideRequest.distance}'),
              const SizedBox(height: 8),
              Text('Estimated Time: ${rideRequest.estimatedTime}'),
              const SizedBox(height: 8),
              Text('Fare: ₱${rideRequest.fareAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'Please wait for a tricycle driver to accept your request.',
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
                Navigator.of(context).pop(rideRequest);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xB2323232),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back $_userName!', // ✅ Firestore name
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userAddress,
                        style: const TextStyle(
                          color: Color(0xFF323232),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'How much will you pay?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _fareController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter fare amount',
                            hintStyle: TextStyle(
                              color: Color(0xFF323232),
                              fontSize: 12,
                            ),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(
                              color: Color(0xFF323232),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = 'Cash';
                              });
                            },
                            child: Container(
                              width: 113,
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
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = 'GCash';
                              });
                            },
                            child: Container(
                              width: 113,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethod == 'GCash'
                                    ? const Color(0xFF0097B2)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'GCash',
                                  style: TextStyle(
                                    color: _selectedPaymentMethod == 'GCash'
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
                                            fontWeight: FontWeight.w700,
                                          ),
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
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    width: 1,
                                    color: const Color(0xFF0097B2),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFF0097B2),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
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
              ),
            ),
            const Positioned(
              left: 31,
              top: 46,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Go',
                      style: TextStyle(
                        color: Color(0xFF0097B2),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' '),
                    TextSpan(
                      text: 'Trike',
                      style: TextStyle(
                        color: Color(0xFFFF9500),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
