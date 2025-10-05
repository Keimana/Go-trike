import 'package:flutter/material.dart';
import '../widgets/card_builder_passenger_terminal.dart';
import '../services/ride_request_service.dart';
import 'terminal_modal_accept.dart';

class TerminalRequestTrikeModal extends StatefulWidget {
  final String terminalId;

  const TerminalRequestTrikeModal({
    super.key,
    required this.terminalId,
  });

  @override
  State<TerminalRequestTrikeModal> createState() =>
      _TerminalRequestTrikeModalState();
}

class _TerminalRequestTrikeModalState extends State<TerminalRequestTrikeModal>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            width: screenWidth,
            height: screenHeight * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header line
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF323232),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Passenger Request List
                Expanded(
                  child: StreamBuilder<List<RideRequest>>(
                    stream: RideRequestService.listenToTerminalRides(
                        widget.terminalId),
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // Error state
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading requests: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      // No data or empty list
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "No passenger requests",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      // Display list of ride requests
                      final rideRequests = snapshot.data!;

                      return ListView.builder(
                        itemCount: rideRequests.length,
                        itemBuilder: (context, index) {
                          final rideRequest = rideRequests[index];

                          return CardBuilderPassengerTerminal(
                            rideRequest: rideRequest,
                            onAccept: () async {
                              print('Accept button pressed for ride: ${rideRequest.id}');
                              
                              // Store context references BEFORE any await
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Show TODA Number modal to get input
                              final todaNumber = await showDialog<String>(
                                context: context,
                                builder: (dialogContext) =>
                                    const TerminalModalAccept(),
                              );

                              print('TODA number entered: $todaNumber');

                              // If TODA number entered, accept the ride
                              if (todaNumber != null && todaNumber.isNotEmpty) {
                                // Check if still mounted
                                if (!mounted) return;
                                
                                // Show loading dialog using stored navigator
                                navigator.push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    barrierDismissible: false,
                                    pageBuilder: (_, __, ___) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                );

                                print('Attempting to update ride status...');
                                print('Ride ID: ${rideRequest.id}');
                                print('Terminal ID: ${widget.terminalId}');
                                print('TODA Number: $todaNumber');

                                // Accept the ride with TODA number
                                try {
                                  final success = await RideRequestService
                                      .updateRideStatus(
                                    rideRequest.id,
                                    widget.terminalId,
                                    RideStatus.accepted,
                                    todaNumber: todaNumber,
                                  );

                                  print('Update result: $success');

                                  // Close loading dialog
                                  if (mounted) {
                                    navigator.pop();
                                  }

                                  if (success && mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Ride accepted by TODA #$todaNumber'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to accept ride request'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error accepting ride: $e');
                                  
                                  // Close loading dialog
                                  if (mounted) {
                                    navigator.pop();
                                  }
                                  
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            onCancel: () async {
                              print('Cancel button pressed for ride: ${rideRequest.id}');
                              
                              // Store context references BEFORE any await
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              // Show loading dialog
                              navigator.push(
                                PageRouteBuilder(
                                  opaque: false,
                                  barrierDismissible: false,
                                  pageBuilder: (_, __, ___) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );

                              // Cancel the ride
                              final success = await RideRequestService
                                  .updateRideStatus(
                                rideRequest.id,
                                widget.terminalId,
                                RideStatus.cancelled,
                              );

                              print('Cancel result: $success');

                              // Close loading dialog
                              if (mounted) {
                                navigator.pop();
                              }

                              if (success && mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Ride request cancelled'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Failed to cancel ride request'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}