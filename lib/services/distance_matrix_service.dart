import 'dart:convert';
import 'dart:math'; // Add this import for mathematical functions
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; //

class DistanceMatrixService {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';

  // Terminal data structure
  static final List<Terminal> terminals = [
    Terminal(
      id: 'terminal1',
      name: 'Tricycle Terminal 1',
      location: const LatLng(15.116888, 120.615710),
      address: 'Telabastagan Terminal 1',
    ),
    Terminal(
      id: 'terminal2', 
      name: 'Tricycle Terminal 2',
      location: const LatLng(15.117600, 120.614200),
      address: 'Telabastagan Terminal 2',
    ),
    Terminal(
      id: 'terminal3',
      name: 'Tricycle Terminal 3', 
      location: const LatLng(15.118200, 120.617200),
      address: 'Telabastagan Terminal 3',
    ),
    Terminal(
      id: 'terminal4',
      name: 'Tricycle Terminal 4',
      location: const LatLng(15.115600, 120.613500),
      address: 'Telabastagan Terminal 4',
    ),
    Terminal(
      id: 'terminal5',
      name: 'Tricycle Terminal 5',
      location: const LatLng(15.115900, 120.616000),
      address: 'Telabastagan Terminal 5',
    ),
  ];

  /// Find nearest terminal using Google Distance Matrix API
  static Future<TerminalAssignment?> findNearestTerminal(LatLng userLocation) async {
    try {
      // Build destinations string for all terminals
      final String destinations = terminals
          .map((terminal) => '${terminal.location.latitude},${terminal.location.longitude}')
          .join('|');

      // Build API URL
      final String url = '$_baseUrl?'
          'origins=${userLocation.latitude},${userLocation.longitude}&'
          'destinations=$destinations&'
          'mode=driving&'
          'units=metric&'
          'departure_time=now&'
          'traffic_model=best_guess&'
          'key=$_apiKey';

      print('Distance Matrix API URL: $url');

      // Make API request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return _processDistanceMatrixResponse(data, userLocation);
        } else {
          print('Distance Matrix API Error: ${data['status']}');
          return _getFallbackNearestTerminal(userLocation);
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return _getFallbackNearestTerminal(userLocation);
      }
    } catch (e) {
      print('Exception in findNearestTerminal: $e');
      return _getFallbackNearestTerminal(userLocation);
    }
  }

  /// Process Distance Matrix API response
  static TerminalAssignment _processDistanceMatrixResponse(
    Map<String, dynamic> data, 
    LatLng userLocation
  ) {
    final List<dynamic> elements = data['rows'][0]['elements'];
    
    Terminal? nearestTerminal;
    Duration? shortestDuration;
    String? distanceText;
    String? durationText;

    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];
      
      if (element['status'] == 'OK') {
        final int durationValue = element['duration']['value']; // seconds
        final Duration duration = Duration(seconds: durationValue);
        
        if (shortestDuration == null || duration < shortestDuration) {
          shortestDuration = duration;
          nearestTerminal = terminals[i];
          distanceText = element['distance']['text'];
          durationText = element['duration']['text'];
        }
      }
    }

    if (nearestTerminal != null) {
      return TerminalAssignment(
        terminal: nearestTerminal,
        userLocation: userLocation,
        distance: distanceText ?? 'Unknown',
        estimatedTime: durationText ?? 'Unknown',
        durationInSeconds: shortestDuration?.inSeconds ?? 0,
      );
    } else {
      return _getFallbackNearestTerminal(userLocation);
    }
  }

  /// Fallback to calculate nearest terminal using Haversine formula
  static TerminalAssignment _getFallbackNearestTerminal(LatLng userLocation) {
    Terminal? nearestTerminal;
    double shortestDistance = double.infinity;

    for (final terminal in terminals) {
      final double distance = _calculateHaversineDistance(
        userLocation.latitude, 
        userLocation.longitude,
        terminal.location.latitude, 
        terminal.location.longitude,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestTerminal = terminal;
      }
    }

    return TerminalAssignment(
      terminal: nearestTerminal!,
      userLocation: userLocation,
      distance: '${shortestDistance.toStringAsFixed(1)} km',
      estimatedTime: 'Estimated',
      durationInSeconds: (shortestDistance * 120).toInt(), // Rough estimate: 2 min per km
    );
  }

  /// Calculate distance using Haversine formula (fallback)
  static double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
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
}

// Data models
class Terminal {
  final String id;
  final String name;
  final LatLng location;
  final String address;

  Terminal({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': address,
    };
  }
}

class TerminalAssignment {
  final Terminal terminal;
  final LatLng userLocation;
  final String distance;
  final String estimatedTime;
  final int durationInSeconds;

  TerminalAssignment({
    required this.terminal,
    required this.userLocation,
    required this.distance,
    required this.estimatedTime,
    required this.durationInSeconds,
  });

  @override
  String toString() {
    return 'Terminal: ${terminal.name}, Distance: $distance, Time: $estimatedTime';
  }
}