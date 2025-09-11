import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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

  // Phone validation
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

  // Firebase authentication
  Future<Map<String, dynamic>> _authenticateUser({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      User? user = await AuthService().signUp(email, password);
      
      if (user != null) {
        // Update user profile with additional info
        await user.updateDisplayName(name);
        
        // Sign out immediately after account creation
        // This prevents automatic navigation to home screen
        await AuthService().signOut();

        return {
          'success': true,
          'message': 'Account created successfully!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create account. Please try again.',
        };
      }
    } on FirebaseAuthException catch (e) {
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
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Handle sign up with manual validation
  Future<void> _handleSignUp() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Manual validation since Form validation isn't available
    String? nameError = _validateField(nameController.text, 'Name');
    String? phoneError = _validateField(phoneController.text, 'Phone Number');
    String? emailError = _validateField(emailController.text, 'Email');
    String? passwordError = _validateField(passwordController.text, 'Password');
    String? confirmError = _validateField(confirmController.text, 'Confirm Password');

    // Check for validation errors
    if (nameError != null) {
      setState(() => _errorMessage = nameError);
      return;
    }
    if (phoneError != null) {
      setState(() => _errorMessage = phoneError);
      return;
    }
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }
    if (confirmError != null) {
      setState(() => _errorMessage = confirmError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authenticateUser(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
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

          // Clear form fields
          nameController.clear();
          phoneController.clear();
          emailController.clear();
          passwordController.clear();
          confirmController.clear();

          // Navigate back to sign-in screen with a slight delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/signin');
            }
          });
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

  // Custom password field widget that matches CustomTextField exactly
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Roboto',
            fontSize: 16,
          ),
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
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
              isVisible 
                  ? Icons.visibility 
                  : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: onVisibilityToggle,
          ),
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

               
                _buildPasswordField(
                  controller: passwordController,
                  hintText: "Password",
                  isVisible: _isPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 12),

                
                _buildPasswordField(
                  controller: confirmController,
                  hintText: "Confirm Password",
                  isVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 18),

                // Sign Up button
                PrimaryButton(
                  text: _isLoading ? "Creating Account..." : "Sign Up",
                  onPressed: () {
                    if (!_isLoading) {
                      _handleSignUp();
                    }
                  },
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