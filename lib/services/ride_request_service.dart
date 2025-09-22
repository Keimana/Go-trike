import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'distance_matrix_service.dart';

class RideRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit ride request to nearest terminal
  static Future<RideRequest?> submitRideRequest({
    required LatLng userLocation,
    required String userName,
    required String userAddress,
    required double fareAmount,
    required String paymentMethod,
  }) async {
    try {
      // Step 1: Find nearest terminal using Distance Matrix API
      print('Finding nearest terminal...');
      final TerminalAssignment? assignment = await DistanceMatrixService.findNearestTerminal(userLocation);
      
      if (assignment == null) {
        throw Exception('Could not find nearest terminal');
      }

      print('Nearest terminal found: ${assignment.terminal.name}');
      print('Distance: ${assignment.distance}, Time: ${assignment.estimatedTime}');

      // Step 2: Create ride request object
      final RideRequest rideRequest = RideRequest(
        id: '', // Will be set by Firestore
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}', // Temporary user ID
        userName: userName,
        userLocation: userLocation,
        userAddress: userAddress,
        assignedTerminal: assignment.terminal,
        fareAmount: fareAmount,
        paymentMethod: paymentMethod,
        status: RideStatus.pending,
        requestTime: DateTime.now(),
        distance: assignment.distance,
        estimatedTime: assignment.estimatedTime,
        durationInSeconds: assignment.durationInSeconds,
      );

      // Step 3: Save to Firebase under the assigned terminal
      print('Saving ride request to Firebase...');
      final DocumentReference docRef = await _firestore
          .collection('terminals')
          .doc(assignment.terminal.id)
          .collection('ride_requests')
          .add(rideRequest.toJson());

      // Update the ride request with the generated ID
      final RideRequest finalRideRequest = rideRequest.copyWith(id: docRef.id);

      // Step 4: Also save to a global rides collection for tracking
      await _firestore
          .collection('rides')
          .doc(docRef.id)
          .set(finalRideRequest.toJson());

      print('Ride request saved successfully with ID: ${docRef.id}');
      return finalRideRequest;

    } catch (e) {
      print('Error submitting ride request: $e');
      return null;
    }
  }

  /// Listen to ride status updates
  static Stream<RideRequest?> listenToRideStatus(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return RideRequest.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Get all pending rides for a specific terminal (for terminal app)
  static Stream<List<RideRequest>> listenToTerminalRides(String terminalId) {
    return _firestore
        .collection('terminals')
        .doc(terminalId)
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RideRequest.fromJson(data);
      }).toList();
    });
  }

  /// Update ride status (for terminal app)
  static Future<void> updateRideStatus(String rideId, String terminalId, RideStatus status) async {
    try {
      // Update in both collections
      await Future.wait([
        _firestore
            .collection('terminals')
            .doc(terminalId)
            .collection('ride_requests')
            .doc(rideId)
            .update({'status': status.toString().split('.').last}),
        
        _firestore
            .collection('rides')
            .doc(rideId)
            .update({'status': status.toString().split('.').last}),
      ]);
      
      print('Ride status updated to: $status');
    } catch (e) {
      print('Error updating ride status: $e');
    }
  }
}

// Ride Request Model
class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final LatLng userLocation;
  final String userAddress;
  final Terminal assignedTerminal;
  final double fareAmount;
  final String paymentMethod;
  final RideStatus status;
  final DateTime requestTime;
  final String distance;
  final String estimatedTime;
  final int durationInSeconds;

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userLocation,
    required this.userAddress,
    required this.assignedTerminal,
    required this.fareAmount,
    required this.paymentMethod,
    required this.status,
    required this.requestTime,
    required this.distance,
    required this.estimatedTime,
    required this.durationInSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userLatitude': userLocation.latitude,
      'userLongitude': userLocation.longitude,
      'userAddress': userAddress,
      'assignedTerminal': assignedTerminal.toJson(),
      'fareAmount': fareAmount,
      'paymentMethod': paymentMethod,
      'status': status.toString().split('.').last,
      'requestTime': Timestamp.fromDate(requestTime),
      'distance': distance,
      'estimatedTime': estimatedTime,
      'durationInSeconds': durationInSeconds,
    };
  }

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userLocation: LatLng(
        json['userLatitude']?.toDouble() ?? 0.0,
        json['userLongitude']?.toDouble() ?? 0.0,
      ),
      userAddress: json['userAddress'] ?? '',
      assignedTerminal: Terminal(
        id: json['assignedTerminal']['id'] ?? '',
        name: json['assignedTerminal']['name'] ?? '',
        location: LatLng(
          json['assignedTerminal']['latitude']?.toDouble() ?? 0.0,
          json['assignedTerminal']['longitude']?.toDouble() ?? 0.0,
        ),
        address: json['assignedTerminal']['address'] ?? '',
      ),
      fareAmount: json['fareAmount']?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? '',
      status: RideStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => RideStatus.pending,
      ),
      requestTime: (json['requestTime'] as Timestamp).toDate(),
      distance: json['distance'] ?? '',
      estimatedTime: json['estimatedTime'] ?? '',
      durationInSeconds: json['durationInSeconds'] ?? 0,
    );
  }

  RideRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    LatLng? userLocation,
    String? userAddress,
    Terminal? assignedTerminal,
    double? fareAmount,
    String? paymentMethod,
    RideStatus? status,
    DateTime? requestTime,
    String? distance,
    String? estimatedTime,
    int? durationInSeconds,
  }) {
    return RideRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userLocation: userLocation ?? this.userLocation,
      userAddress: userAddress ?? this.userAddress,
      assignedTerminal: assignedTerminal ?? this.assignedTerminal,
      fareAmount: fareAmount ?? this.fareAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      requestTime: requestTime ?? this.requestTime,
      distance: distance ?? this.distance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
    );
  }
}

enum RideStatus {
  pending,
  accepted,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
}