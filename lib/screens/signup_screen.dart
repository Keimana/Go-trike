import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/signup_email_verify.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation (basic)
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  // Password strength validation
  bool _isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  // Form validation
  String? _validateField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    switch (fieldName.toLowerCase()) {
      case 'name':
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        break;
      case 'phone number':
        if (!_isValidPhone(value)) {
          return 'Please enter a valid phone number';
        }
        break;
      case 'email':
        if (!_isValidEmail(value)) {
          return 'Please enter a valid email address';
        }
        break;
      case 'password':
        if (!_isStrongPassword(value)) {
          return 'Password must be at least 8 characters with uppercase, lowercase, and number';
        }
        break;
      case 'confirm password':
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        break;
    }
    return null;
  }

  // Test Firestore connection
  Future<void> _testFirestore() async {
    try {
      print('🔥 Testing Firestore connection...');
      await FirebaseFirestore.instance.collection('test').doc('test').set({
        'message': 'Hello Firestore',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore test successful!');
    } catch (e) {
      print('❌ Firestore test failed: $e');
    }
  }

  // Simplified Firebase authentication
  Future<Map<String, dynamic>> _authenticateUser({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting authentication for: $email');
      
      // Create user account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      User? user = userCredential.user;
      debugPrint('User created: ${user?.uid}');
      
      if (user != null) {
        try {
          // Update display name in Firebase Auth
          await user.updateDisplayName(name);
          print('Display name updated');
          
          // Store user data in Firestore with timeout and retry logic
          try {
            print('Attempting to store user data in Firestore for UID: ${user.uid}');
            
            final userData = {
              'name': name,
              'phone': phone,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            };
            
            print('User data to store: $userData');
            
            // Add timeout to prevent hanging
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set(userData)
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw Exception('Firestore write timeout after 10 seconds');
                  },
                );
            
            print('✅ User data successfully stored in Firestore');
          } catch (firestoreError) {
            print('❌ Firestore error: $firestoreError');
            
            // Try a simpler write without serverTimestamp
            try {
              print('Retrying with simpler data...');
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                    'name': name,
                    'phone': phone,
                    'email': email,
                  })
                  .timeout(const Duration(seconds: 5));
              print('✅ Retry successful - user data stored');
            } catch (retryError) {
              print('❌ Retry also failed: $retryError');
              // Continue anyway - at least the account exists
            }
          }
          
          return {
            'success': true,
            'message': 'Account created successfully!',
            'user': user,
          };
        } catch (profileError) {
          debugPrint('Profile update error: $profileError');
          // Even if profile update fails, the account was created
          return {
            'success': true,
            'message': 'Account created successfully!',
            'user': user,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to create account. Please try again.',
        };
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      debugPrint('General error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Handle sign up with manual validation
  Future<void> _handleSignUp() async {
    debugPrint('Sign up button clicked');
    
    // Prevent multiple taps
    if (_isLoading) {
      debugPrint('Already loading, ignoring tap');
      return;
    }

    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Manual validation
      String? nameError = _validateField(nameController.text, 'Name');
      String? phoneError = _validateField(phoneController.text, 'Phone Number');
      String? emailError = _validateField(emailController.text, 'Email');
      String? passwordError = _validateField(passwordController.text, 'Password');
      String? confirmError = _validateField(confirmController.text, 'Confirm Password');

      // Check for validation errors
      if (nameError != null) {
        setState(() {
          _errorMessage = nameError;
          _isLoading = false;
        });
        return;
      }
      if (phoneError != null) {
        setState(() {
          _errorMessage = phoneError;
          _isLoading = false;
        });
        return;
      }
      if (emailError != null) {
        setState(() {
          _errorMessage = emailError;
          _isLoading = false;
        });
        return;
      }
      if (passwordError != null) {
        setState(() {
          _errorMessage = passwordError;
          _isLoading = false;
        });
        return;
      }
      if (confirmError != null) {
        setState(() {
          _errorMessage = confirmError;
          _isLoading = false;
        });
        return;
      }

      debugPrint('Validation passed, authenticating user');

      final result = await _authenticateUser(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('Authentication result: ${result['success']}');

      if (result['success']) {
        if (mounted) {
          debugPrint('Account created successfully, navigating back to sign in');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to sign-in screen
          Navigator.pop(context);
        }
      } else {
        debugPrint('Authentication failed: ${result['message']}');
        if (mounted) {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _handleSignUp: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Go Trike Title
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Go ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0097B2),
                        ),
                      ),
                      TextSpan(
                        text: 'Trike',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Form fields
                CustomTextField(
                  hintText: "Name",
                  controller: nameController,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hintText: "Phone Number",
                  controller: phoneController,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hintText: "Email",
                  controller: emailController,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: confirmController,
                ),
                const SizedBox(height: 18),

                // Sign Up button
                PrimaryButton(
                  text: _isLoading ? "Creating Account..." : "Sign Up",
                  onPressed: _isLoading ? null : _handleSignUp,
                ),
                
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),

                const SizedBox(height: 20),

                // Sign In link
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: _isLoading 
                              ? Colors.grey 
                              : const Color(0xFF0097B2),
                        ),
                        children: [
                          const TextSpan(text: "Have an account? "),
                          TextSpan(
                            text: "Sign In",
                            style: TextStyle(
                              color: _isLoading 
                                  ? Colors.grey 
                                  : const Color(0xFF000000),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}