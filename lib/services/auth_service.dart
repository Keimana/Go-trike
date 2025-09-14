import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
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
      return result.user;
    } catch (e) {
      print('Error in signUp: $e');
      return null;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification([User? userToVerify]) async {
    try {
      User? user = userToVerify ?? _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Verification email sent to: ${user.email}');
        return true;
      }
      print('User is null or already verified');
      return false;
    } catch (e) {
      print('Error in sendEmailVerification: $e');
      return false;
    }
  }

  // Check if email exists (for signup validation)
  Future<bool> doesEmailExist(String email) async {
    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Reload user to get the latest email verification status
        await user.reload();
        user = _auth.currentUser; // Get the refreshed user
        return user?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      print('Error in isEmailVerified: $e');
      return false;
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
    } catch (e) {
      print('Error in signOut: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}