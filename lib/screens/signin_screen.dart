import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import 'EmailVerificationScreen.dart';
import '../onboarding/onboarding_screen.dart';
import 'phone_otp.dart';


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

  // Firebase authentication
  Future<Map<String, dynamic>> _authenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final authService = AuthService();
      User? user = await authService.signIn(email, password);
      
      if (user != null) {
        return {
          'success': true,
          'message': ' ',
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
    setState(() {
      _errorMessage = null;
    });

    String? emailError = _validateField(emailController.text, 'Email');
    String? passwordError = _validateField(passwordController.text, 'Password');

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
        User? user = result['user'];
        
        if (user != null) {
          // Check if email is verified
          if (!user.emailVerified) {
            // Email not verified - send verification email
            final authService = AuthService();
            final emailResult = await authService.sendEmailVerification();
            
            if (mounted) {
              if (emailResult['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent! Please check your inbox.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(emailResult['message']),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              
              // Navigate to email verification screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationScreen(
                    email: emailController.text.trim(),
                  ),
                ),
              );
            }
            return;
          }
          
          // Email is verified, check phone verification
          final authService = AuthService();
          final isPhoneVerified = await authService.isPhoneVerified();
          if (!isPhoneVerified) {
            // Phone not verified - navigate to phone verification
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please verify your phone number'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );

              await Future.delayed(const Duration(seconds: 1));

              // Get phone from Firestore
              final phoneNumber = await authService.getUserPhoneNumber(user.uid);
              
              if (phoneNumber == null || phoneNumber.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number not found. Please contact support.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                }
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PhoneOTPVerificationScreen(
                    phoneNumber: phoneNumber,
                    userId: user.uid,
                  ),
                ),
              );
            }
            return;
          }
          
          // Both email and phone verified - proceed to home
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login Successful!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            await Future.delayed(const Duration(seconds: 1));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        }
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

  // Handle forgot password
  Future<void> _handleForgotPassword() async {
    String? emailError = _validateField(emailController.text, 'Email');
    
    if (emailError != null) {
      setState(() => _errorMessage = 'Please enter a valid email address first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final result = await authService.sendPasswordResetEmail(emailController.text.trim());
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent! Check your inbox.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
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
                                color: Color(0xFF1B4871),
                              ),
                            ),
                            TextSpan(
                              text: 'Trike',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEAAD39),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logo
                      Image.asset('assets/images/trike.png', height: 250),
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

                      // Password input
                      CustomTextField(
                        hintText: "Password",
                        obscureText: true,
                        controller: passwordController,
                      ),
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
                            color: _isLoading ? Colors.grey : const Color(0xFF1B4871),
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
                                color: _isLoading ? Colors.grey : const Color(0xFF1B4871),
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
          },
        ),
      ),
    );
  }
}