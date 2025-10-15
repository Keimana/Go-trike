import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a report for a TODA
  static Future<bool> submitReport({
    required String rideId,
    required String todaNumber,
    required String userAddress,
    required String destinationAddress,
    required List<String> issues,
    String? additionalComments,
  }) async {
    try {
      print('🔍 === STARTING REPORT SUBMISSION ===');
      
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return false;
      }
      print('User authenticated: ${currentUser.uid}');

      if (issues.isEmpty) {
        print('No issues selected');
        return false;
      }
      print('Issues selected: $issues');

      final String reportId = _firestore.collection('reports').doc().id;
      print('Generated report ID: $reportId');
      
      final Map<String, dynamic> reportData = {
        'id': reportId,
        'rideId': rideId,
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'userEmail': currentUser.email ?? '',
        'todaNumber': todaNumber,
        'issues': issues,
        'additionalComments': additionalComments,
        'userAddress': userAddress,
        'destinationAddress': destinationAddress,
        'status': 'pending',
        'reportTime': Timestamp.now(),
        'reviewedTime': null,
        'resolvedTime': null,
        'adminNotes': null,
      };

      print('📦 Report data prepared:');
      print('   Ride ID: $rideId');
      print('   TODA: $todaNumber');
      print('   Issues: $issues');
      print('   User: ${currentUser.email}');

      // Save to main reports collection
      print('💾 Saving to reports collection...');
      await _firestore
          .collection('reports')
          .doc(reportId)
          .set(reportData);
      print('✅ Saved to reports collection');

      // Save to user's reports subcollection for easy access
      print('💾 Saving to user reports subcollection...');
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('reports')
          .doc(reportId)
          .set(reportData);
      print('✅ Saved to user reports subcollection');

      // Save to TODA-specific reports for tracking
      print('💾 Saving to TODA reports collection...');
      await _firestore
          .collection('toda_reports')
          .doc(todaNumber)
          .collection('reports')
          .doc(reportId)
          .set(reportData);
      print('✅ Saved to TODA reports collection');

      // Update report count on the TODA document
      print('💾 Updating TODA statistics...');
      final todaRef = _firestore.collection('toda_reports').doc(todaNumber);
      await _firestore.runTransaction((transaction) async {
        final todaDoc = await transaction.get(todaRef);
        
        if (todaDoc.exists) {
          final currentCount = todaDoc.data()?['totalReports'] ?? 0;
          transaction.update(todaRef, {
            'totalReports': currentCount + 1,
            'lastReportTime': Timestamp.now(),
          });
          print('✅ Updated existing TODA stats (count: ${currentCount + 1})');
        } else {
          transaction.set(todaRef, {
            'todaNumber': todaNumber,
            'totalReports': 1,
            'lastReportTime': Timestamp.now(),
            'createdAt': Timestamp.now(),
          });
          print('✅ Created new TODA stats document');
        }
      });

      print('🎉 Report submitted successfully: $reportId');
      print('=== REPORT SUBMISSION COMPLETE ===');
      return true;

    } catch (e, stackTrace) {
      print('❌ =====================================');
      print('❌ ERROR SUBMITTING REPORT');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ =====================================');
      return false;
    }
  }

  /// Get user's reports
  static Stream<List<Report>> listenToUserReports({String? userId}) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = userId ?? currentUser?.uid ?? '';
    
    if (uid.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .orderBy('reportTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Report.fromJson(data);
      }).toList();
    });
  }

  /// Get all reports for a specific TODA
  static Stream<List<Report>> listenToTodaReports(String todaNumber) {
    return _firestore
        .collection('toda_reports')
        .doc(todaNumber)
        .collection('reports')
        .orderBy('reportTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Report.fromJson(data);
      }).toList();
    });
  }

  /// Get TODA statistics
  static Future<TodaReportStats?> getTodaStats(String todaNumber) async {
    try {
      final doc = await _firestore
          .collection('toda_reports')
          .doc(todaNumber)
          .get();

      if (doc.exists) {
        return TodaReportStats.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting TODA stats: $e');
      return null;
    }
  }
}

class Report {
  final String id;
  final String rideId;
  final String userId;
  final String userName;
  final String userEmail;
  final String todaNumber;
  final List<String> issues;
  final String? additionalComments;
  final String userAddress;
  final String destinationAddress;
  final String status;
  final DateTime reportTime;
  final DateTime? reviewedTime;
  final DateTime? resolvedTime;
  final String? adminNotes;

  Report({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.todaNumber,
    required this.issues,
    this.additionalComments,
    required this.userAddress,
    required this.destinationAddress,
    required this.status,
    required this.reportTime,
    this.reviewedTime,
    this.resolvedTime,
    this.adminNotes,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      todaNumber: json['todaNumber'] ?? '',
      issues: (json['issues'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      additionalComments: json['additionalComments'],
      userAddress: json['userAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      status: json['status'] ?? 'pending',
      reportTime: (json['reportTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedTime: (json['reviewedTime'] as Timestamp?)?.toDate(),
      resolvedTime: (json['resolvedTime'] as Timestamp?)?.toDate(),
      adminNotes: json['adminNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'todaNumber': todaNumber,
      'issues': issues,
      'additionalComments': additionalComments,
      'userAddress': userAddress,
      'destinationAddress': destinationAddress,
      'status': status,
      'reportTime': Timestamp.fromDate(reportTime),
      'reviewedTime': reviewedTime != null ? Timestamp.fromDate(reviewedTime!) : null,
      'resolvedTime': resolvedTime != null ? Timestamp.fromDate(resolvedTime!) : null,
      'adminNotes': adminNotes,
    };
  }
}

class TodaReportStats {
  final String todaNumber;
  final int totalReports;
  final DateTime? lastReportTime;
  final DateTime createdAt;

  TodaReportStats({
    required this.todaNumber,
    required this.totalReports,
    this.lastReportTime,
    required this.createdAt,
  });

  factory TodaReportStats.fromJson(Map<String, dynamic> json) {
    return TodaReportStats(
      todaNumber: json['todaNumber'] ?? '',
      totalReports: json['totalReports'] ?? 0,
      lastReportTime: (json['lastReportTime'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}