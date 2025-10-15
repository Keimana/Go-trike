import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../widgets/history_card_builder.dart';
import 'settings_screen.dart';
import 'report_toda_screen.dart';
import '../services/ride_request_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  String _formatRideTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('h:mm a').format(time).toLowerCase();
    } else if (difference.inDays == 1) {
      // Yesterday - show time
      return DateFormat('h:mm a').format(time).toLowerCase();
    } else {
      // Past dates - show date
      return DateFormat('MMM d').format(time);
    }
  }

  String _calculateDuration(RideRequest ride) {
    if (ride.completedTime != null && ride.inProgressTime != null) {
      final duration = ride.completedTime!.difference(ride.inProgressTime!);
      return '${duration.inMinutes} min';
    } else if (ride.completedTime != null && ride.acceptedTime != null) {
      final duration = ride.completedTime!.difference(ride.acceptedTime!);
      return '${duration.inMinutes} min';
    }
    return ride.estimatedTime;
  }

  String _getDateSection(DateTime rideTime) {
    final now = DateTime.now();
    final difference = now.difference(rideTime);

    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays <= 30) {
      return "Past Month";
    } else {
      return "Older";
    }
  }

  Map<String, List<RideRequest>> _groupRidesByDate(List<RideRequest> rides) {
    final Map<String, List<RideRequest>> grouped = {
      "Today": [],
      "Yesterday": [],
      "Past Month": [],
      "Older": [],
    };

    for (final ride in rides) {
      final completedTime = ride.completedTime ?? ride.requestTime;
      final section = _getDateSection(completedTime);
      grouped[section]?.add(ride);
    }

    // Remove empty sections
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    // Add authentication check
    final currentUser = FirebaseAuth.instance.currentUser;
    print('🔐 ActivityLogsScreen - Current User: ${currentUser?.uid}');
    print('🔐 ActivityLogsScreen - User Email: ${currentUser?.email}');

    return Scaffold(
      body: Stack(
        children: [
          // Check authentication first
          if (currentUser == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: h * 0.02),
                  const Text(
                    'Not authenticated',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: h * 0.01),
                  const Text(
                    'Please sign in to view your activity logs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            // Scrollable content
            StreamBuilder<List<RideRequest>>(
              stream: RideRequestService.listenToUserRides(),
              builder: (context, snapshot) {
                print('📊 ActivityLogsScreen StreamBuilder State:');
                print('   ConnectionState: ${snapshot.connectionState}');
                print('   HasError: ${snapshot.hasError}');
                print('   HasData: ${snapshot.hasData}');
                print('   Data length: ${snapshot.data?.length ?? 0}');
                
                if (snapshot.hasError) {
                  print('   Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0097B2)),
                        ),
                        SizedBox(height: h * 0.02),
                        const Text(
                          'Loading activity logs...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        SizedBox(height: h * 0.02),
                        const Text(
                          'Error loading activity logs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: h * 0.01),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: h * 0.02),
                        ElevatedButton(
                          onPressed: () {
                            // Trigger rebuild
                            (context as Element).markNeedsBuild();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0097B2),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allRides = snapshot.data ?? [];
                print('✅ Total rides received: ${allRides.length}');
                
                // Filter only completed rides
                final completedRides = allRides
                    .where((ride) => ride.status == RideStatus.completed)
                    .toList();

                print('✅ Completed rides: ${completedRides.length}');
                if (completedRides.isNotEmpty) {
                  print('   First completed ride ID: ${completedRides.first.id}');
                  print('   First completed ride status: ${completedRides.first.status}');
                }

                if (completedRides.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: h * 0.02),
                        const Text(
                          'No ride history yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: h * 0.01),
                        const Text(
                          'Your completed rides will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: h * 0.02),
                        Text(
                          'Total rides: ${allRides.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Completed: ${completedRides.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final logsByDate = _groupRidesByDate(completedRides);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: h * 0.12), // space for floating button

                          // Screen title
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                            child: const Text(
                              'Activity Logs',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.02),

                          // Logs grouped by date
                          ...logsByDate.entries.map((entry) {
                            final sectionTitle = entry.key;
                            final rides = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                                  child: Text(
                                    sectionTitle,
                                    style: TextStyle(
                                      fontSize: w * 0.045,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                SizedBox(height: h * 0.008),

                                // Divider
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: w * 0.03, vertical: h * 0.01),
                                  child: Container(
                                    width: w * 0.9,
                                    height: 0.5,
                                    decoration: const ShapeDecoration(
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 0.5,
                                          strokeAlign: BorderSide.strokeAlignCenter,
                                          color: Color.fromARGB(255, 179, 179, 179),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: h * 0.01),

                                // History cards
                                ...rides.map(
                                  (ride) {
                                    final completedTime = ride.completedTime ?? ride.requestTime;
                                    final timeString = _formatRideTime(completedTime);
                                    final duration = _calculateDuration(ride);
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          bottom: h * 0.02, left: w * 0.03),
                                      child: HistoryCardBuilder(
                                        title: "Go Trike",
                                        price: "₱${ride.fareAmount.toStringAsFixed(2)}",
                                        subtitle: "$timeString | $duration",
                                        toda: ride.todaNumber ?? "N/A",
                                        pickup: ride.userAddress,
                                        locationHistory: ride.destinationAddress,
                                        onActionTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReportTodaScreen(
                                                toda: ride.todaNumber ?? "N/A",
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }),

                          SizedBox(height: h * 0.04),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          Positioned(
            top: safeTop + h * 0.02, // safe distance + proportional offset
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
        ],
      ),
    );
  }
}