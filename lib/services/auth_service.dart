import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime? _lastEmailSentTime;
  static const int _emailCooldownSeconds = 60;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        // Update last login time in Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      return result.user;
    } catch (e) {
      print('Error in signIn: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        // Initialize user document in Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Send verification email
        await result.user?.sendEmailVerification();
        _lastEmailSentTime = DateTime.now();
        print('Verification email sent to $email');
      }
      
      return result.user;
    } catch (e) {
      print('Error in signUp: $e');
      return null;
    }
  }

  // Check if email is verified (simple Firebase check)
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send email verification with rate limiting
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently signed in',
        };
      }
      
      // Check cooldown
      if (_lastEmailSentTime != null) {
        final timeSinceLastEmail = DateTime.now().difference(_lastEmailSentTime!);
        if (timeSinceLastEmail.inSeconds < _emailCooldownSeconds) {
          final remainingSeconds = _emailCooldownSeconds - timeSinceLastEmail.inSeconds;
          return {
            'success': false,
            'message': 'Please wait $remainingSeconds seconds before requesting another email',
            'cooldown': remainingSeconds,
          };
        }
      }
      
      // Send the email
      await user.sendEmailVerification();
      _lastEmailSentTime = DateTime.now();
      print('✅ Verification email sent to ${user.email}');
      
      return {
        'success': true,
        'message': 'Verification email sent successfully',
      };
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send email: ${e.message}';
      }
      
      print('❌ Firebase Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Error sending verification email: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Reload user to get latest email verification status
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        print('🔄 User reloaded');
      }
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error in sendPasswordResetEmail: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _lastEmailSentTime = null;
    } catch (e) {
      print('Error in signOut: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}