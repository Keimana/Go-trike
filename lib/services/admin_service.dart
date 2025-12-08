import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== DIAGNOSTIC CHECK ====================
  
  static Future<void> checkFirestoreConnection() async {
    try {
      print('🔍 Checking Firestore connection...');
      
      // Check authentication
      final User? user = FirebaseAuth.instance.currentUser;
      print('👤 Current user: ${user?.uid ?? "NOT LOGGED IN"}');
      print('📧 User email: ${user?.email ?? "N/A"}');
      
      if (user == null) {
        print('❌ ERROR: No user is logged in! Please authenticate first.');
        return;
      }
      
      // Check user document
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        print('👤 User document exists: ${userDoc.exists}');
        if (userDoc.exists) {
          print('👤 User data: ${userDoc.data()}');
          print('👤 Is Admin: ${userDoc.data()?['isAdmin'] ?? false}');
        } else {
          print('⚠️ WARNING: User document does not exist in Firestore!');
        }
      } catch (e) {
        print('❌ Error fetching user document: $e');
      }
      
      // Check each collection
      final collections = [
        'reports',
        'rides', 
        'users',
        'drivers',
        'terminals',
        'admin_activities'
      ];
      
      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).limit(1).get();
          print('📊 Collection "$collection": ${snapshot.docs.length} docs (sample)');
          if (snapshot.docs.isNotEmpty) {
            print('   Sample data: ${snapshot.docs.first.data()}');
          }
        } catch (e) {
          print('❌ Error reading "$collection": $e');
        }
      }
      
      print('✅ Firestore connection check complete!');
    } catch (e, stackTrace) {
      print('❌ Fatal error during connection check: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ==================== REPORTS ====================
  
  static Stream<List<AdminReport>> listenToAllReports() {
    print('🔍 Setting up reports stream...');
    
    return _firestore
        .collection('reports')
        .orderBy('reportTime', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📄 Reports snapshot received: ${snapshot.docs.length} documents');
          
          if (snapshot.docs.isEmpty) {
            print('⚠️ No reports found in Firestore');
          }
          
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              print('📄 Parsing report: ${doc.id}');
              return AdminReport.fromJson(data);
            } catch (e) {
              print('❌ Error parsing report ${doc.id}: $e');
              return AdminReport(
                id: doc.id,
                rideId: 'error',
                todaNumber: 'Unknown',
                cause: 'Data parsing error',
                reporter: 'System',
                reportTime: DateTime.now(),
                status: 'error',
                additionalComments: 'Error loading comments',
              );
            }
          }).toList();
        })
        .handleError((error) {
          print('❌ Reports stream error: $error');
          return <AdminReport>[];
        });
  }

  // ==================== ACTIVITY LOGS ====================
  
  static Stream<List<TodaActivityLog>> listenToActivityLogs() {
    print('🔍 Setting up activity logs stream...');
    
    return _firestore
        .collection('rides')
        .where('status', whereIn: ['accepted', 'rejected', 'cancelled', 'completed'])
        .snapshots()
        .map((snapshot) {
          print('📄 Activity logs snapshot: ${snapshot.docs.length} documents');
          
          Map<String, TodaActivityLog> todaMap = {};
          
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final todaNumber = data['todaNumber']?.toString() ?? 'Unknown';
              final status = data['status']?.toString() ?? '';

              if (!todaMap.containsKey(todaNumber)) {
                todaMap[todaNumber] = TodaActivityLog(
                  todaName: todaNumber,
                  accepted: 0,
                  rejected: 0,
                );
              }
              
              if (status == 'accepted' || status == 'completed') {
                todaMap[todaNumber]!.accepted++;
              } else if (status == 'rejected' || status == 'cancelled') {
                todaMap[todaNumber]!.rejected++;
              }
            } catch (e) {
              print('❌ Error processing ride ${doc.id}: $e');
            }
          }
          
          print('📊 Processed ${todaMap.length} TODA groups');
          return todaMap.values.toList();
        })
        .handleError((error) {
          print('❌ Activity logs stream error: $error');
          return <TodaActivityLog>[];
        });
  }

  // ==================== RIDE HISTORY ====================
  
  static Stream<List<RideHistoryEntry>> listenToRideHistory() {
    print('🔍 Setting up ride history stream...');
    
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'completed')
        // Temporarily remove orderBy until index is created:
        // .orderBy('completedTime', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📄 Ride history snapshot: ${snapshot.docs.length} documents');
          
          // Manually sort on client side as temporary solution
          final rides = snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              return RideHistoryEntry(
                riderName: data['todaNumber']?.toString() ?? 'Unknown',
                pickup: data['userAddress']?.toString() ?? 'N/A',
                dropoff: data['destinationAddress']?.toString() ?? 'N/A',
                price: (data['fareAmount'] as num?)?.toDouble() ?? 0.0,
                completedTime: (data['completedTime'] as Timestamp?)?.toDate(),
              );
            } catch (e) {
              print('❌ Error parsing ride ${doc.id}: $e');
              return RideHistoryEntry(
                riderName: 'Unknown',
                pickup: 'N/A',
                dropoff: 'N/A',
                price: 0.0,
                completedTime: DateTime.now(),
              );
            }
          }).toList();
          
          // Client-side sorting by completedTime (newest first)
          rides.sort((a, b) => (b.completedTime ?? DateTime.now())
              .compareTo(a.completedTime ?? DateTime.now()));
          
          return rides;
        })
        .handleError((error) {
          print('❌ Ride history stream error: $error');
          return <RideHistoryEntry>[];
        });
  }

  // ==================== ADMIN ACTIVITIES ====================
  
  static Stream<List<AdminActivity>> listenToAdminActivities() {
    print('🔍 Setting up admin activities stream...');
    
    return _firestore
        .collection('admin_activities')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📄 Admin activities snapshot: ${snapshot.docs.length} documents');
          
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              return AdminActivity(
                date: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                activity: data['activity']?.toString() ?? 'Unknown activity',
                adminId: data['adminId']?.toString() ?? '',
              );
            } catch (e) {
              print('❌ Error parsing admin activity ${doc.id}: $e');
              return AdminActivity(
                date: DateTime.now(),
                activity: 'Data parsing error',
                adminId: 'error',
              );
            }
          }).toList();
        })
        .handleError((error) {
          print('❌ Admin activities stream error: $error');
          return <AdminActivity>[];
        });
  }

  static Future<void> logAdminActivity(String activity) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ No user logged in for admin activity logging');
        return;
      }

      await _firestore.collection('admin_activities').add({
        'adminId': currentUser.uid,
        'activity': activity,
        'timestamp': Timestamp.now(),
      });
      print('✅ Admin activity logged: $activity');
    } catch (e, stackTrace) {
      print('❌ Error logging admin activity: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ==================== USERS ====================
  
  static Stream<List<UserEntry>> listenToUsers() {
    print('🔍 Setting up users stream...');
    
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          print('📄 Users snapshot: ${snapshot.docs.length} documents');
          
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              return UserEntry(
                id: doc.id,
                name: data['displayName']?.toString() ?? data['name']?.toString() ?? 'Unknown',
                email: data['email']?.toString() ?? 'N/A',
                status: (data['isActive'] ?? true) ? 'Active' : 'Inactive',
                joinedDate: (data['createdAt'] as Timestamp?)?.toDate(),
              );
            } catch (e) {
              print('❌ Error parsing user ${doc.id}: $e');
              return UserEntry(
                id: doc.id,
                name: 'Unknown',
                email: 'N/A',
                status: 'Error',
                joinedDate: DateTime.now(),
              );
            }
          }).toList();
        })
        .handleError((error) {
          print('❌ Users stream error: $error');
          return <UserEntry>[];
        });
  }

  // ==================== DRIVERS ====================
  
  static Stream<List<DriverEntry>> listenToDrivers() {
    print('🔍 Setting up drivers stream...');
    
    return _firestore
        .collection('drivers')
        .snapshots()
        .map((snapshot) {
          print('📄 Drivers snapshot: ${snapshot.docs.length} documents');
          
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              return DriverEntry(
                id: doc.id,
                name: data['name']?.toString() ?? 'Unknown',
                todaNumber: data['todaNumber']?.toString() ?? 'N/A',
                status: (data['isActive'] ?? true) ? 'Active' : 'Inactive',
              );
            } catch (e) {
              print('❌ Error parsing driver ${doc.id}: $e');
              return DriverEntry(
                id: doc.id,
                name: 'Unknown',
                todaNumber: 'N/A',
                status: 'Error',
              );
            }
          }).toList();
        })
        .handleError((error) {
          print('❌ Drivers stream error: $error');
          return <DriverEntry>[];
        });
  }

  // ==================== TERMINAL MANAGEMENT ====================
  
  static Future<bool> addTerminal({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('terminals').add({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
      
      await logAdminActivity('Added new terminal: $name');
      print('✅ Terminal added: $name');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error adding terminal: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> deleteTerminal(String terminalId) async {
    try {
      await _firestore.collection('terminals').doc(terminalId).delete();
      await logAdminActivity('Deleted terminal: $terminalId');
      print('✅ Terminal deleted: $terminalId');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error deleting terminal: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}

// ==================== DATA MODELS ====================

class AdminReport {
  final String id;
  final String rideId;
  final String todaNumber;
  final String cause;
  final String reporter;
  final DateTime reportTime;
  final String status;
  final String? additionalComments; // Added this field

  AdminReport({
    required this.id,
    required this.rideId,
    required this.todaNumber,
    required this.cause,
    required this.reporter,
    required this.reportTime,
    required this.status,
    this.additionalComments, // Added this field
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    String cause = 'Unknown';
    if (json['issues'] != null && json['issues'] is List) {
      final issues = json['issues'] as List;
      if (issues.isNotEmpty) {
        cause = issues.join(', ');
      }
    } else if (json['cause'] != null) {
      cause = json['cause'].toString();
    }

    return AdminReport(
      id: json['id']?.toString() ?? '',
      rideId: json['rideId']?.toString() ?? '',
      todaNumber: json['todaNumber']?.toString() ?? 'Unknown',
      cause: cause,
      reporter: json['userName']?.toString() ?? json['reporter']?.toString() ?? 'Anonymous',
      reportTime: (json['reportTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      additionalComments: json['additionalComments']?.toString(), 
    );
  }
}

class TodaActivityLog {
  final String todaName;
  int accepted;
  int rejected;

  TodaActivityLog({
    required this.todaName,
    required this.accepted,
    required this.rejected,
  });
}

class RideHistoryEntry {
  final String riderName;
  final String pickup;
  final String dropoff;
  final double price;
  final DateTime? completedTime;

  RideHistoryEntry({
    required this.riderName,
    required this.pickup,
    required this.dropoff,
    required this.price,
    this.completedTime,
  });
}

class AdminActivity {
  final DateTime date;
  final String activity;
  final String adminId;

  AdminActivity({
    required this.date,
    required this.activity,
    required this.adminId,
  });
}

class UserEntry {
  final String id;
  final String name;
  final String email;
  final String status;
  final DateTime? joinedDate;

  UserEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.joinedDate,
  });
}

class DriverEntry {
  final String id;
  final String name;
  final String todaNumber;
  final String status;

  DriverEntry({
    required this.id,
    required this.name,
    required this.todaNumber,
    required this.status,
  });
}