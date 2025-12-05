import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Singleton AuthService
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime? _lastEmailSentTime;
  static const int _emailCooldownSeconds = 60;

  // Phone verification properties
  String? _verificationId;
  int? _resendToken;

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

  // ==================== PHONE AUTHENTICATION ====================
  
  /// Send OTP to phone number with retry logic
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerified,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        print('📱 Attempt ${attempts + 1}: Sending OTP to: $phoneNumber');
        
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          
          // Called when verification is completed automatically (Android only)
          verificationCompleted: (PhoneAuthCredential credential) async {
            print('✅ Phone verification completed automatically');
            try {
              await _auth.currentUser?.updatePhoneNumber(credential);
              
              // Update phone verification status in Firestore
              if (_auth.currentUser != null) {
                await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
                  'phone': phoneNumber,
                  'phoneVerified': true,
                  'phoneVerifiedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
              
              onAutoVerified();
            } catch (e) {
              print('❌ Error in auto verification: $e');
              onError('Auto verification failed: ${e.toString()}');
            }
          },
          
          // Called when verification fails
          verificationFailed: (FirebaseAuthException e) {
            print('❌ Phone verification failed: ${e.code} - ${e.message}');
            
            String errorMessage;
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = 'Invalid phone number format';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many requests. Please try again later.';
                // Wait longer for this specific error
                Future.delayed(const Duration(seconds: 10), () {
                  if (attempts < maxRetries - 1) {
                    attempts++;
                    // Don't call onError, let it retry
                  } else {
                    onError(errorMessage);
                  }
                });
                return; // Exit early, will retry
              case 'quota-exceeded':
                errorMessage = 'SMS quota exceeded. Please try again later';
                break;
              case 'network-request-failed':
                errorMessage = 'Network error. Please check your connection';
                break;
              default:
                errorMessage = 'Verification failed: ${e.message ?? "Unknown error"}';
            }
            
            onError(errorMessage);
          },
          
          // Called when code is sent
          codeSent: (String verificationId, int? resendToken) {
            print('📨 OTP code sent. Verification ID: $verificationId');
            _verificationId = verificationId;
            _resendToken = resendToken;
            onCodeSent(verificationId);
          },
          
          // Called when auto-retrieval timeout
          codeAutoRetrievalTimeout: (String verificationId) {
            print('⏱️ Auto retrieval timeout');
            _verificationId = verificationId;
          },
          
          // Use resend token if available
          forceResendingToken: _resendToken,
        );
        return; // Success, exit function
      } catch (e) {
        attempts++;
        print('❌ Error sending OTP (attempt $attempts): $e');
        
        if (attempts >= maxRetries) {
          onError('Failed to send OTP after $maxRetries attempts: ${e.toString()}');
        } else {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      }
    }
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP(String otpCode) async {
    try {
      if (_verificationId == null) {
        return {
          'success': false,
          'message': 'Verification ID not found. Please request OTP again.',
        };
      }

      print('🔐 Verifying OTP code: $otpCode');

      // Create credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      // Update phone number for current user
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently signed in',
        };
      }

      await user.updatePhoneNumber(credential);
      
      // Update Firestore with phone verification status
      await _firestore.collection('users').doc(user.uid).set({
        'phone': user.phoneNumber ?? '', // Store as string
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Phone number verified successfully');

      return {
        'success': true,
        'message': 'Phone verified successfully',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code. Please check and try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP has expired. Please request a new one.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'credential-already-in-use':
          errorMessage = 'This phone number is already in use by another account.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message ?? "Unknown error"}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Check if phone is verified from Firestore
  Future<bool> isPhoneVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['phoneVerified'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking phone verification: $e');
      return false;
    }
  }

  /// Get current phone number from Firestore
  Future<String?> getUserPhoneNumber(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['phone']?.toString();
      }
      return null;
    } catch (e) {
      print('Error fetching phone number: $e');
      return null;
    }
  }

  /// Get current phone number from Auth
  String? getCurrentPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  // ==================== END PHONE AUTHENTICATION ====================

  // Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _lastEmailSentTime = null;
      _verificationId = null;
      _resendToken = null;
    } catch (e) {
      print('Error in signOut: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
}