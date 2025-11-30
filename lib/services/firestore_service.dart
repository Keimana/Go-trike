import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  static FirebaseFirestore? _instance;
  
  static FirebaseFirestore get instance {
    if (_instance == null) {
      try {
        _instance = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: '(default)', // Use '(default)' for the default database
          //databaseId: 'gotrike', // Uncomment if you have a named database
        );
      } catch (e) {
        print('Error initializing Firestore: $e');
        // Fallback to default instance
        _instance = FirebaseFirestore.instance;
      }
    }
    return _instance!;
  }
}