import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// Sign up screen for new user registration
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;

  // Constants
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static const Duration _retryTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkFirestoreConnection();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Initialize text editing controllers
  void _initializeControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  /// Dispose text editing controllers
  void _disposeControllers() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  /// Check Firestore connection and log connection details
  Future<void> _checkFirestoreConnection() async {
    try {
      debugPrint('Checking Firestore connection...');

      // Test Firestore read capability
      await FirebaseFirestore.instance
          .collection('test')
          .limit(1)
          .get()
          .timeout(_timeoutDuration);
      
      debugPrint('Firestore connection established successfully');

      // Log current user status
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('Current authenticated user: ${currentUser.uid}');
      } else {
        debugPrint('No authenticated user found');
      }

      // Log Firestore settings
      final settings = FirebaseFirestore.instance.settings;
      debugPrint('Firestore configuration - Host: ${settings.host}, SSL: ${settings.sslEnabled}');
    } catch (error, stackTrace) {
      debugPrint('Firestore connection check failed: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Validate name field
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate phone field
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate email field
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password field
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$').hasMatch(value)) {
      return 'Password must be at least 8 characters with uppercase, lowercase, and number';
    }
    return null;
  }

  /// Validate confirm password field
  String? _validateConfirmPassword(String password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate all form fields
  List<String> _validateForm() {
    final errors = <String>[];

    final nameError = _validateName(_nameController.text);
    if (nameError != null) errors.add(nameError);

    final phoneError = _validatePhone(_phoneController.text);
    if (phoneError != null) errors.add(phoneError);

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) errors.add(emailError);

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) errors.add(passwordError);

    final confirmPasswordError = _validateConfirmPassword(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    if (confirmPasswordError != null) errors.add(confirmPasswordError);

    return errors;
  }

  /// Create user account with Firebase Auth
  Future<UserCredential> _createUserAccount(String email, String password) async {
    debugPrint('Creating user account for email: $email');
    
    return await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
        .timeout(_timeoutDuration);
  }

  /// Update user profile information
  Future<void> _updateUserProfile(User user, String name) async {
    try {
      await user.updateDisplayName(name);
      debugPrint('User display name updated successfully');
    } catch (error) {
      debugPrint('Failed to update user display name: $error');
      // Continue execution as this is not critical
    }
  }

  /// Create user data map for Firestore
  Map<String, dynamic> _createUserData({
    required String uid,
    required String name,
    required String phone,
    required String email,
  }) {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Store user data in Firestore
  Future<void> _storeUserData({
    required String uid,
    required String name,
    required String phone,
    required String email,
  }) async {
    debugPrint('Storing user data in Firestore for UID: $uid');

    final userData = _createUserData(
      uid: uid,
      name: name,
      phone: phone,
      email: email,
    );

    try {
      // Primary attempt with server timestamp
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData)
          .timeout(_timeoutDuration);

      debugPrint('User data successfully stored in Firestore');

      // Verify the write operation
      await _verifyUserDataWrite(uid);
    } catch (error) {
      debugPrint('Primary Firestore write failed: $error');
      await _retryUserDataWrite(uid, name, phone, email);
    }
  }

  /// Verify that user data was written successfully
  Future<void> _verifyUserDataWrite(String uid) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        debugPrint('User document verified in Firestore');
      } else {
        debugPrint('Warning: User document not found after write');
      }
    } catch (error) {
      debugPrint('Failed to verify user document: $error');
    }
  }

  /// Retry user data write with simplified structure
  Future<void> _retryUserDataWrite(String uid, String name, String phone, String email) async {
    try {
      debugPrint('Retrying Firestore write with simplified data structure');
      
      final simplifiedData = {
        'name': name,
        'phone': phone,
        'email': email,
        'created': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(simplifiedData)
          .timeout(_retryTimeout);

      debugPrint('Retry write operation successful');
    } catch (retryError) {
      debugPrint('Retry write operation failed: $retryError');
      // Allow the process to continue even if Firestore write fails
    }
  }

  /// Handle the complete user registration process
  Future<AuthResult> _registerUser() async {
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Create Firebase Auth account
      final userCredential = await _createUserAccount(email, password);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.failure('Account creation failed. Please try again.');
      }

      debugPrint('User account created successfully: ${user.uid}');

      // Update user profile
      await _updateUserProfile(user, name);

      // Store user data in Firestore
      await _storeUserData(
        uid: user.uid,
        name: name,
        phone: phone,
        email: email,
      );

      return AuthResult.success('Account created successfully!', user);
    } on FirebaseAuthException catch (authError) {
      debugPrint('Firebase Auth error: ${authError.code} - ${authError.message}');
      return AuthResult.failure(_getAuthErrorMessage(authError));
    } catch (error, stackTrace) {
      debugPrint('Registration error: $error');
      debugPrint('Stack trace: $stackTrace');
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// Get user-friendly error message from FirebaseAuthException
  String _getAuthErrorMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'email-already-in-use':
        return 'This email address is already registered. Please use a different email or sign in.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Handle sign up button press
  Future<void> _handleSignUp() async {
    if (_isLoading) {
      debugPrint('Sign up already in progress, ignoring duplicate request');
      return;
    }

    debugPrint('Starting sign up process');

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Validate form
      final validationErrors = _validateForm();
      if (validationErrors.isNotEmpty) {
        setState(() {
          _errorMessage = validationErrors.first;
          _isLoading = false;
        });
        return;
      }

      debugPrint('Form validation passed, proceeding with registration');

      // Register user
      final result = await _registerUser();

      if (!mounted) return;

      if (result.isSuccess) {
        debugPrint('Registration completed successfully');
        _showSuccessMessage();
        Navigator.pop(context);
      } else {
        debugPrint('Registration failed: ${result.message}');
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (error) {
      debugPrint('Unexpected error in sign up handler: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
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

  /// Show success message to user
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully! Please sign in.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Handle navigation to sign in screen
  void _navigateToSignIn() {
    if (!_isLoading) {
      Navigator.pop(context);
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
                _buildTitle(),
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 24),
                _buildErrorMessage(),
                _buildFormFields(),
                const SizedBox(height: 18),
                _buildSignUpButton(),
                _buildLoadingIndicator(),
                const SizedBox(height: 20),
                _buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build app title
  Widget _buildTitle() {
    return const Text.rich(
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
    );
  }

  /// Build subtitle
  Widget _buildSubtitle() {
    return const Text(
      "Sign Up",
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build error message display
  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
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
    );
  }

  /// Build form input fields
  Widget _buildFormFields() {
    return Column(
      children: [
        CustomTextField(
          hintText: "Name",
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          hintText: "Phone Number",
          controller: _phoneController,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          hintText: "Email",
          controller: _emailController,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          hintText: "Password",
          obscureText: true,
          controller: _passwordController,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          hintText: "Confirm Password",
          obscureText: true,
          controller: _confirmPasswordController,
        ),
      ],
    );
  }

  /// Build sign up button
  Widget _buildSignUpButton() {
    return PrimaryButton(
      text: _isLoading ? "Creating Account..." : "Sign Up",
      onPressed: _isLoading ? null : _handleSignUp,
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: CircularProgressIndicator(),
    );
  }

  /// Build sign in navigation link
  Widget _buildSignInLink() {
    return Center(
      child: GestureDetector(
        onTap: _navigateToSignIn,
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
    );
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String message;
  final User? user;

  const AuthResult._({
    required this.isSuccess,
    required this.message,
    this.user,
  });

  factory AuthResult.success(String message, User user) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}