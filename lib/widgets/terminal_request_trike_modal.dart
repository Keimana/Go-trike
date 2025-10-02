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
                              // Show TODA Number modal to get input
                              final todaNumber = await showDialog<String>(
                                context: context,
                                builder: (context) =>
                                    const TerminalModalAccept(),
                              );

                              // If TODA number entered, accept the ride
                              if (todaNumber != null && todaNumber.isNotEmpty && mounted) {
                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Accept the ride with TODA number
                                final success = await RideRequestService
                                    .updateRideStatus(
                                  rideRequest.id,
                                  widget.terminalId,
                                  RideStatus.accepted,
                                  todaNumber: todaNumber,
                                );

                                // Close loading dialog
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Ride accepted by TODA #$todaNumber'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Failed to accept ride request'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            onCancel: () async {
                              // Show loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              // Cancel the ride
                              final success = await RideRequestService
                                  .updateRideStatus(
                                rideRequest.id,
                                widget.terminalId,
                                RideStatus.cancelled,
                              );

                              // Close loading dialog
                              if (mounted) {
                                Navigator.of(context).pop();
                              }

                              if (success && mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Ride request cancelled'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
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