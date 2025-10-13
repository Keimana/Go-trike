import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'distance_matrix_service.dart';

class RideRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int TERMINAL_TIMEOUT_SECONDS = 30;
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';

  /// Submit ride request with cascading terminal assignment
  static Future<RideRequest?> submitRideRequest({
    required LatLng userLocation,
    required String userName,
    required String userAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required double fareAmount,
    required String paymentMethod,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Finding all terminals sorted by distance...');
      final List<TerminalAssignment> sortedTerminals = 
          await _getAllTerminalsSortedByDistance(userLocation);
      
      if (sortedTerminals.isEmpty) {
        throw Exception('No terminals available');
      }

      final String requestId = _firestore.collection('rides').doc().id;
      
      final RideRequest initialRequest = RideRequest(
        id: requestId,
        userId: currentUser.uid,
        userName: userName.isNotEmpty ? userName : (currentUser.displayName ?? 'User'),
        userLocation: userLocation,
        userAddress: userAddress,
        destinationLocation: destinationLocation,
        destinationAddress: destinationAddress,
        assignedTerminal: sortedTerminals[0].terminal,
        fareAmount: fareAmount,
        paymentMethod: paymentMethod,
        status: RideStatus.pending,
        requestTime: DateTime.now(),
        distance: sortedTerminals[0].distance,
        estimatedTime: sortedTerminals[0].estimatedTime,
        durationInSeconds: sortedTerminals[0].durationInSeconds,
        terminalAssignmentIndex: 0,
        sortedTerminalIds: sortedTerminals.map((t) => t.terminal.id).toList(),
      );

      await _firestore
          .collection('rides')
          .doc(requestId)
          .set(initialRequest.toJson());

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('rides')
          .doc(requestId)
          .set(initialRequest.toJson());

      await _assignToTerminal(initialRequest, sortedTerminals[0].terminal);

      _startCascadingTimer(requestId, sortedTerminals);

      print('Ride request submitted successfully with cascading enabled');
      return initialRequest;

    } catch (e) {
      print('Error submitting ride request: $e');
      return null;
    }
  }

  static Future<List<TerminalAssignment>> _getAllTerminalsSortedByDistance(
      LatLng userLocation) async {
    try {
      final List<Terminal> terminals = DistanceMatrixService.terminals;
      
      final String destinations = terminals
          .map((terminal) => '${terminal.location.latitude},${terminal.location.longitude}')
          .join('|');

      final String url = '$_baseUrl?'
          'origins=${userLocation.latitude},${userLocation.longitude}&'
          'destinations=$destinations&'
          'mode=driving&'
          'units=metric&'
          'departure_time=now&'
          'traffic_model=best_guess&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return _processAllTerminalsResponse(data, userLocation, terminals);
        }
      }
      
      return _getFallbackSortedTerminals(userLocation, terminals);
      
    } catch (e) {
      print('Error getting sorted terminals: $e');
      return _getFallbackSortedTerminals(userLocation, DistanceMatrixService.terminals);
    }
  }

  static List<TerminalAssignment> _processAllTerminalsResponse(
    Map<String, dynamic> data,
    LatLng userLocation,
    List<Terminal> terminals,
  ) {
    final List<dynamic> elements = data['rows'][0]['elements'];
    final List<TerminalAssignment> assignments = [];

    for (int i = 0; i < elements.length && i < terminals.length; i++) {
      final element = elements[i];
      
      if (element['status'] == 'OK') {
        final int durationValue = element['duration']['value'];
        
        assignments.add(TerminalAssignment(
          terminal: terminals[i],
          userLocation: userLocation,
          distance: element['distance']['text'],
          estimatedTime: element['duration']['text'],
          durationInSeconds: durationValue,
        ));
      }
    }

    assignments.sort((a, b) => a.durationInSeconds.compareTo(b.durationInSeconds));
    
    return assignments;
  }

  static List<TerminalAssignment> _getFallbackSortedTerminals(
    LatLng userLocation,
    List<Terminal> terminals,
  ) {
    final List<TerminalAssignment> assignments = [];

    for (final terminal in terminals) {
      final double distance = _calculateHaversineDistance(
        userLocation.latitude,
        userLocation.longitude,
        terminal.location.latitude,
        terminal.location.longitude,
      );

      assignments.add(TerminalAssignment(
        terminal: terminal,
        userLocation: userLocation,
        distance: '${distance.toStringAsFixed(1)} km',
        estimatedTime: 'Estimated',
        durationInSeconds: (distance * 120).toInt(),
      ));
    }

    assignments.sort((a, b) => a.durationInSeconds.compareTo(b.durationInSeconds));
    
    return assignments;
  }

  static double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = 
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        (sin(dLon / 2) * sin(dLon / 2));
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static Future<void> _assignToTerminal(RideRequest request, Terminal terminal) async {
    await _firestore
        .collection('terminals')
        .doc(terminal.id)
        .collection('ride_requests')
        .doc(request.id)
        .set(request.toJson());
    
    print('Assigned ride ${request.id} to terminal: ${terminal.name}');
  }

  static Future<void> _removeFromTerminal(String rideId, String terminalId) async {
    await _firestore
        .collection('terminals')
        .doc(terminalId)
        .collection('ride_requests')
        .doc(rideId)
        .delete();
    
    print('Removed ride $rideId from terminal: $terminalId');
  }

  static void _startCascadingTimer(
    String rideId,
    List<TerminalAssignment> sortedTerminals,
  ) {
    int currentIndex = 0;
    
    Timer.periodic(Duration(seconds: TERMINAL_TIMEOUT_SECONDS), (timer) async {
      try {
        final rideDoc = await _firestore.collection('rides').doc(rideId).get();
        
        if (!rideDoc.exists) {
          print('Ride $rideId no longer exists, stopping cascade');
          timer.cancel();
          return;
        }

        final rideData = rideDoc.data()!;
        final status = rideData['status'];
        
        if (status != 'pending') {
          print('Ride $rideId status is $status, stopping cascade');
          timer.cancel();
          return;
        }

        currentIndex++;
        
        if (currentIndex >= sortedTerminals.length) {
          print('All terminals exhausted for ride $rideId');
          
          final lastTerminalId = sortedTerminals[currentIndex - 1].terminal.id;
          await _removeFromTerminal(rideId, lastTerminalId);
          
          await _firestore.collection('rides').doc(rideId).update({
            'status': 'no_driver_available',
            'noDriverTime': Timestamp.now(),
          });

          final userId = rideData['userId'];
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rides')
              .doc(rideId)
              .update({
            'status': 'no_driver_available',
            'noDriverTime': Timestamp.now(),
          });
          
          print('Ride marked as no_driver_available');
          timer.cancel();
          return;
        }

        final previousTerminal = sortedTerminals[currentIndex - 1].terminal;
        await _removeFromTerminal(rideId, previousTerminal.id);

        final nextAssignment = sortedTerminals[currentIndex];
        final nextTerminal = nextAssignment.terminal;
        
        final Map<String, dynamic> updateData = {
          'assignedTerminal': nextTerminal.toJson(),
          'distance': nextAssignment.distance,
          'estimatedTime': nextAssignment.estimatedTime,
          'durationInSeconds': nextAssignment.durationInSeconds,
          'terminalAssignmentIndex': currentIndex,
          'lastTerminalSwitchTime': Timestamp.now(),
        };

        await _firestore.collection('rides').doc(rideId).update(updateData);
        
        final userId = rideData['userId'];
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rides')
            .doc(rideId)
            .update(updateData);

        final updatedRequest = RideRequest.fromJson({
          ...rideData,
          ...updateData,
          'id': rideId,
        });
        
        await _assignToTerminal(updatedRequest, nextTerminal);
        
        print('Cascaded ride $rideId to terminal: ${nextTerminal.name} (${currentIndex + 1}/${sortedTerminals.length})');
        
      } catch (e) {
        print('Error in cascading timer: $e');
        timer.cancel();
      }
    });
  }

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

  static Future<bool> updateRideStatus(
    String rideId,
    String terminalId,
    RideStatus status,
    {String? driverId, String? driverName, String? todaNumber}
  ) async {
    try {
      print('=== UPDATE RIDE STATUS ===');
      print('Ride ID: $rideId');
      print('Terminal ID: $terminalId');
      print('Status: $status');

      final Map<String, dynamic> updateData = {
        'status': status.toString().split('.').last,
      };

      if (todaNumber != null && todaNumber.isNotEmpty) {
        updateData['todaNumber'] = todaNumber;
      }

      switch (status) {
        case RideStatus.accepted:
          updateData['acceptedTime'] = Timestamp.now();
          updateData['acceptedTerminalId'] = terminalId;
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

      await _firestore
          .collection('terminals')
          .doc(terminalId)
          .collection('ride_requests')
          .doc(rideId)
          .update(updateData);

      await _firestore
          .collection('rides')
          .doc(rideId)
          .update(updateData);
      
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (rideDoc.exists) {
        final userId = rideDoc.data()?['userId'];
        if (userId != null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rides')
              .doc(rideId)
              .update(updateData);
        }
      }
      
      print('Ride status updated successfully to: $status');
      return true;
    } catch (e) {
      print('❌ ERROR updating ride status: $e');
      return false;
    }
  }

  static Future<bool> cancelRideRequest(String rideId) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final rideData = rideDoc.data()!;
      final terminalId = rideData['assignedTerminal']['id'];

      return await updateRideStatus(rideId, terminalId, RideStatus.cancelled);
    } catch (e) {
      print('Error cancelling ride request: $e');
      return false;
    }
  }
}

class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final LatLng userLocation;
  final String userAddress;
  final LatLng destinationLocation;
  final String destinationAddress;
  final Terminal assignedTerminal;
  final double fareAmount;
  final String paymentMethod;
  final RideStatus status;
  final DateTime requestTime;
  final String distance;
  final String estimatedTime;
  final int durationInSeconds;
  
  final int terminalAssignmentIndex;
  final List<String> sortedTerminalIds;
  final DateTime? lastTerminalSwitchTime;
  
  final String? todaNumber;
  final String? acceptedTerminalId;
  final DateTime? acceptedTime;
  final DateTime? enRouteTime;
  final DateTime? arrivedTime;
  final DateTime? inProgressTime;
  final DateTime? completedTime;
  final DateTime? cancelledTime;
  final DateTime? noDriverTime;

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userLocation,
    required this.userAddress,
    required this.destinationLocation,
    required this.destinationAddress,
    required this.assignedTerminal,
    required this.fareAmount,
    required this.paymentMethod,
    required this.status,
    required this.requestTime,
    required this.distance,
    required this.estimatedTime,
    required this.durationInSeconds,
    this.terminalAssignmentIndex = 0,
    this.sortedTerminalIds = const [],
    this.lastTerminalSwitchTime,
    this.todaNumber,
    this.acceptedTerminalId,
    this.acceptedTime,
    this.enRouteTime,
    this.arrivedTime,
    this.inProgressTime,
    this.completedTime,
    this.cancelledTime,
    this.noDriverTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userLatitude': userLocation.latitude,
      'userLongitude': userLocation.longitude,
      'userAddress': userAddress,
      'destinationLatitude': destinationLocation.latitude,
      'destinationLongitude': destinationLocation.longitude,
      'destinationAddress': destinationAddress,
      'assignedTerminal': assignedTerminal.toJson(),
      'fareAmount': fareAmount,
      'paymentMethod': paymentMethod,
      'status': status.toString().split('.').last,
      'requestTime': Timestamp.fromDate(requestTime),
      'distance': distance,
      'estimatedTime': estimatedTime,
      'durationInSeconds': durationInSeconds,
      'terminalAssignmentIndex': terminalAssignmentIndex,
      'sortedTerminalIds': sortedTerminalIds,
      'lastTerminalSwitchTime': lastTerminalSwitchTime != null 
          ? Timestamp.fromDate(lastTerminalSwitchTime!) 
          : null,
      'todaNumber': todaNumber,
      'acceptedTerminalId': acceptedTerminalId,
      'acceptedTime': acceptedTime != null ? Timestamp.fromDate(acceptedTime!) : null,
      'enRouteTime': enRouteTime != null ? Timestamp.fromDate(enRouteTime!) : null,
      'arrivedTime': arrivedTime != null ? Timestamp.fromDate(arrivedTime!) : null,
      'inProgressTime': inProgressTime != null ? Timestamp.fromDate(inProgressTime!) : null,
      'completedTime': completedTime != null ? Timestamp.fromDate(completedTime!) : null,
      'cancelledTime': cancelledTime != null ? Timestamp.fromDate(cancelledTime!) : null,
      'noDriverTime': noDriverTime != null ? Timestamp.fromDate(noDriverTime!) : null,
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
      destinationLocation: LatLng(
        json['destinationLatitude']?.toDouble() ?? 0.0,
        json['destinationLongitude']?.toDouble() ?? 0.0,
      ),
      destinationAddress: json['destinationAddress'] ?? '',
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
      status: _parseStatus(json['status']),
      requestTime: (json['requestTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      distance: json['distance'] ?? '',
      estimatedTime: json['estimatedTime'] ?? '',
      durationInSeconds: json['durationInSeconds'] ?? 0,
      terminalAssignmentIndex: json['terminalAssignmentIndex'] ?? 0,
      sortedTerminalIds: (json['sortedTerminalIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      lastTerminalSwitchTime: (json['lastTerminalSwitchTime'] as Timestamp?)?.toDate(),
      todaNumber: json['todaNumber'],
      acceptedTerminalId: json['acceptedTerminalId'],
      acceptedTime: (json['acceptedTime'] as Timestamp?)?.toDate(),
      enRouteTime: (json['enRouteTime'] as Timestamp?)?.toDate(),
      arrivedTime: (json['arrivedTime'] as Timestamp?)?.toDate(),
      inProgressTime: (json['inProgressTime'] as Timestamp?)?.toDate(),
      completedTime: (json['completedTime'] as Timestamp?)?.toDate(),
      cancelledTime: (json['cancelledTime'] as Timestamp?)?.toDate(),
      noDriverTime: (json['noDriverTime'] as Timestamp?)?.toDate(),
    );
  }

  static RideStatus _parseStatus(String? status) {
    if (status == 'no_driver_available') {
      return RideStatus.noDriverAvailable;
    }
    return RideStatus.values.firstWhere(
      (s) => s.toString().split('.').last == status,
      orElse: () => RideStatus.pending,
    );
  }

  RideRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    LatLng? userLocation,
    String? userAddress,
    LatLng? destinationLocation,
    String? destinationAddress,
    Terminal? assignedTerminal,
    double? fareAmount,
    String? paymentMethod,
    RideStatus? status,
    DateTime? requestTime,
    String? distance,
    String? estimatedTime,
    int? durationInSeconds,
    int? terminalAssignmentIndex,
    List<String>? sortedTerminalIds,
    DateTime? lastTerminalSwitchTime,
    String? todaNumber,
    String? acceptedTerminalId,
    DateTime? acceptedTime,
    DateTime? enRouteTime,
    DateTime? arrivedTime,
    DateTime? inProgressTime,
    DateTime? completedTime,
    DateTime? cancelledTime,
    DateTime? noDriverTime,
  }) {
    return RideRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userLocation: userLocation ?? this.userLocation,
      userAddress: userAddress ?? this.userAddress,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      assignedTerminal: assignedTerminal ?? this.assignedTerminal,
      fareAmount: fareAmount ?? this.fareAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      requestTime: requestTime ?? this.requestTime,
      distance: distance ?? this.distance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      terminalAssignmentIndex: terminalAssignmentIndex ?? this.terminalAssignmentIndex,
      sortedTerminalIds: sortedTerminalIds ?? this.sortedTerminalIds,
      lastTerminalSwitchTime: lastTerminalSwitchTime ?? this.lastTerminalSwitchTime,
      todaNumber: todaNumber ?? this.todaNumber,
      acceptedTerminalId: acceptedTerminalId ?? this.acceptedTerminalId,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      enRouteTime: enRouteTime ?? this.enRouteTime,
      arrivedTime: arrivedTime ?? this.arrivedTime,
      inProgressTime: inProgressTime ?? this.inProgressTime,
      completedTime: completedTime ?? this.completedTime,
      cancelledTime: cancelledTime ?? this.cancelledTime,
      noDriverTime: noDriverTime ?? this.noDriverTime,
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
  noDriverAvailable,
}