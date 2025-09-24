import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

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
        userId: currentUser.uid,
        userName: userName.isNotEmpty ? userName : (currentUser.displayName ?? 'User'),
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

      // Step 5: Save to user's personal rides collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
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
      if (snapshot.exists && snapshot.data() != null) {
        return RideRequest.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Get current user's rides
  static Stream<List<RideRequest>> listenToUserRides({String? userId}) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = userId ?? currentUser?.uid ?? '';
    
    if (uid.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('rides')
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
  static Future<bool> updateRideStatus(String rideId, String terminalId, RideStatus status, {String? driverId, String? driverName}) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': status.toString().split('.').last,
      };

      // Add driver info if provided
      if (driverId != null) updateData['driverId'] = driverId;
      if (driverName != null) updateData['driverName'] = driverName;

      // Update status change timestamp
      switch (status) {
        case RideStatus.accepted:
          updateData['acceptedTime'] = Timestamp.now();
          break;
        case RideStatus.enRoute:
          updateData['enRouteTime'] = Timestamp.now();
          break;
        case RideStatus.arrived:
          updateData['arrivedTime'] = Timestamp.now();
          break;
        case RideStatus.inProgress:
          updateData['inProgressTime'] = Timestamp.now();
          break;
        case RideStatus.completed:
          updateData['completedTime'] = Timestamp.now();
          break;
        case RideStatus.cancelled:
          updateData['cancelledTime'] = Timestamp.now();
          break;
        default:
          break;
      }

      // Update in all collections
      await Future.wait([
        _firestore
            .collection('terminals')
            .doc(terminalId)
            .collection('ride_requests')
            .doc(rideId)
            .update(updateData),
        
        _firestore
            .collection('rides')
            .doc(rideId)
            .update(updateData),
      ]);
      
      // Also update in user's rides collection
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (rideDoc.exists) {
        final rideData = rideDoc.data();
        final userId = rideData?['userId'];
        if (userId != null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rides')
              .doc(rideId)
              .update(updateData);
        }
      }
      
      print('Ride status updated to: $status');
      return true;
    } catch (e) {
      print('Error updating ride status: $e');
      return false;
    }
  }

  /// Cancel ride request (for user)
  static Future<bool> cancelRideRequest(String rideId) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Get ride info first
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final rideData = rideDoc.data()!;
      final terminalId = rideData['assignedTerminal']['id'];

      // Update status to cancelled
      return await updateRideStatus(rideId, terminalId, RideStatus.cancelled);
    } catch (e) {
      print('Error cancelling ride request: $e');
      return false;
    }
  }
}

// Ride Request Model (same as your original with some enhancements)
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
  
  // Additional fields for tracking
  final String? driverId;
  final String? driverName;
  final DateTime? acceptedTime;
  final DateTime? enRouteTime;
  final DateTime? arrivedTime;
  final DateTime? inProgressTime;
  final DateTime? completedTime;
  final DateTime? cancelledTime;

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
    this.driverId,
    this.driverName,
    this.acceptedTime,
    this.enRouteTime,
    this.arrivedTime,
    this.inProgressTime,
    this.completedTime,
    this.cancelledTime,
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
      'driverId': driverId,
      'driverName': driverName,
      'acceptedTime': acceptedTime != null ? Timestamp.fromDate(acceptedTime!) : null,
      'enRouteTime': enRouteTime != null ? Timestamp.fromDate(enRouteTime!) : null,
      'arrivedTime': arrivedTime != null ? Timestamp.fromDate(arrivedTime!) : null,
      'inProgressTime': inProgressTime != null ? Timestamp.fromDate(inProgressTime!) : null,
      'completedTime': completedTime != null ? Timestamp.fromDate(completedTime!) : null,
      'cancelledTime': cancelledTime != null ? Timestamp.fromDate(cancelledTime!) : null,
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
      requestTime: (json['requestTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      distance: json['distance'] ?? '',
      estimatedTime: json['estimatedTime'] ?? '',
      durationInSeconds: json['durationInSeconds'] ?? 0,
      driverId: json['driverId'],
      driverName: json['driverName'],
      acceptedTime: (json['acceptedTime'] as Timestamp?)?.toDate(),
      enRouteTime: (json['enRouteTime'] as Timestamp?)?.toDate(),
      arrivedTime: (json['arrivedTime'] as Timestamp?)?.toDate(),
      inProgressTime: (json['inProgressTime'] as Timestamp?)?.toDate(),
      completedTime: (json['completedTime'] as Timestamp?)?.toDate(),
      cancelledTime: (json['cancelledTime'] as Timestamp?)?.toDate(),
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
    String? driverId,
    String? driverName,
    DateTime? acceptedTime,
    DateTime? enRouteTime,
    DateTime? arrivedTime,
    DateTime? inProgressTime,
    DateTime? completedTime,
    DateTime? cancelledTime,
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
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      enRouteTime: enRouteTime ?? this.enRouteTime,
      arrivedTime: arrivedTime ?? this.arrivedTime,
      inProgressTime: inProgressTime ?? this.inProgressTime,
      completedTime: completedTime ?? this.completedTime,
      cancelledTime: cancelledTime ?? this.cancelledTime,
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