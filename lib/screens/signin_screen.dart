import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

final authService = AuthService();

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Form validation
  String? _validateField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    switch (fieldName.toLowerCase()) {
      case 'email':
        if (!_isValidEmail(value)) {
          return 'Please enter a valid email address';
        }
        break;
      case 'password':
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        break;
    }
    return null;
  }

  // Firebase authentication with email verification check
  Future<Map<String, dynamic>> _authenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      User? user = await authService.signIn(email, password);
      
      if (user != null) {
        // Check if email is verified
        bool isVerified = await authService.isEmailVerified();
        
        if (!isVerified) {
          return {
            'success': false,
            'message': 'Please verify your email address before signing in.',
            'needsVerification': true,
            'user': user,
          };
        }
        
        return {
          'success': true,
          'message': 'Welcome back!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to sign in. Please try again.',
        };
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please check your credentials.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Handle sign in
  Future<void> _handleSignIn() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Manual validation
    String? emailError = _validateField(emailController.text, 'Email');
    String? passwordError = _validateField(passwordController.text, 'Password');

    // Check for validation errors
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authenticateUser(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else if (result['needsVerification'] == true) {
        // Show email verification dialog
        _showEmailVerificationBottomSheet();
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show email verification bottom sheet
  void _showEmailVerificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Email verification icon
              Icon(
                Icons.email_outlined,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Please check your email and click the verification link to activate your account.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Resend verification email button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // Sign in again to get the user object for sending verification
                      User? user = await authService.signIn(
                        emailController.text.trim(), 
                        passwordController.text
                      );
                      
                      if (user != null) {
                        bool sent = await authService.sendEmailVerification(user);
                        
                        // Sign out immediately after sending verification
                        await authService.signOut();
                        
                        if (sent) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification email sent! Please check your inbox.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to send verification email. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to resend verification email.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error sending verification email.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097B2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Resend Verification Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // I've verified button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close bottom sheet
                    
                    // Check verification status
                    bool isVerified = await authService.isEmailVerified();
                    if (isVerified) {
                      // Navigate to home page
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email verified successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      }
                    } else {
                      // Show error
                      if (mounted) {
                        setState(() {
                          _errorMessage = 'Email not verified yet. Please check your email and try again.';
                        });
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0097B2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'I\'ve Verified My Email',
                    style: TextStyle(
                      color: Color(0xFF0097B2),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Cancel button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authService.signOut(); // Sign out the unverified user
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle forgot password
  Future<void> _handleForgotPassword() async {
    String? emailError = _validateField(emailController.text, 'Email');
    
    if (emailError != null) {
      setState(() => _errorMessage = 'Please enter a valid email address first');
      return;
    }

    try {
      await authService.sendPasswordResetEmail(emailController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reset email. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Custom password field widget to match CustomTextField styling
  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto',
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF0097B2),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible 
                ? Icons.visibility 
                : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Go Trike title
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
              ),
              const SizedBox(height: 16),

              // Logo
              Image.asset('assets/images/trike.png', height: 100),
              const SizedBox(height: 16),

              const Text(
                "Hello!",
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

              // Email input
              CustomTextField(
                hintText: "Email",
                controller: emailController,
              ),
              const SizedBox(height: 12),

              _buildPasswordField(),
              const SizedBox(height: 18),

              // Login button
              PrimaryButton(
                text: _isLoading ? "Signing In..." : "Login",
                onPressed: () {
                  if (!_isLoading) {
                    _handleSignIn();
                  }
                },
              ),
              const SizedBox(height: 12),

              // Forgot password
              GestureDetector(
                onTap: _isLoading ? null : _handleForgotPassword,
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : const Color(0xFF0097B2),
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pushNamed(context, '/signup'),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: _isLoading ? Colors.grey : const Color(0xFF0097B2),
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: _isLoading ? Colors.grey : const Color(0xFF000000),
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
    );
  }
}