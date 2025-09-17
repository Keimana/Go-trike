// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class UserService {
//   final CollectionReference users =
//       FirebaseFirestore.instance.collection('users');

//   Future<void> createUserProfile({
//     required String uid,
//     required String name,
//     required String phone,
//     required String email,
//   }) async {
//     try {
//       print("Creating user profile for uid: $uid"); // Debug log
      
//       await users.doc(uid).set({
//         'uid': uid, // Include uid in the document
//         'name': name,
//         'phone': phone,
//         'email': email,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
      
//       print("User profile created successfully"); // Debug log
//     } catch (e) {
//       print("Error saving user profile: $e");
//       rethrow;
//     }
//   }

//   Future<DocumentSnapshot> getUserProfile(String uid) async {
//     try {
//       print("Fetching user profile for uid: $uid"); // Debug log
      
//       DocumentSnapshot snapshot = await users.doc(uid).get();
      
//       print("Document exists: ${snapshot.exists}"); // Debug log
//       if (snapshot.exists) {
//         print("User data: ${snapshot.data()}"); // Debug log
//       }
      
//       return snapshot;
//     } catch (e) {
//       print("Error fetching user profile: $e");
//       rethrow;
//     }
//   }

//   Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
//     try {
//       await users.doc(uid).update(data);
//       print("User profile updated successfully");
//     } catch (e) {
//       print("Error updating user profile: $e");
//       rethrow;
//     }
//   }
// }