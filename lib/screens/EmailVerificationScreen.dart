import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../onboarding/onboarding_screen.dart'; // Changed from home_page
import 'signin_screen.dart';

final authService = AuthService();

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = false;
  int resendCooldown = 60;
  Timer? cooldownTimer;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    
    // Check immediately on init
    checkEmailVerified();
    
    // Check every 3 seconds if email is verified
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkEmailVerified(),
    );
    
    // Start cooldown for resend button
    startResendCooldown();
  }

  void startResendCooldown() {
    setState(() {
      canResendEmail = false;
      resendCooldown = 60;
    });
    
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown > 0) {
        setState(() {
          resendCooldown--;
        });
      } else {
        setState(() {
          canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> checkEmailVerified() async {
    if (isChecking) return;
    
    setState(() {
      isChecking = true;
    });

    try {
      // Reload user to get latest verification status
      await authService.reloadUser();
      
      // Check if email is verified
      bool emailVerified = authService.isEmailVerified();
      
      print('🔍 Checking email verification: $emailVerified');
      
      if (emailVerified) {
        print('✅ Email verified! Proceeding to onboarding...');
        
        setState(() {
          isEmailVerified = true;
        });

        timer?.cancel();
        cooldownTimer?.cancel();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(seconds: 1));
          
          if (mounted) {
            // Get current user ID
            final currentUser = FirebaseAuth.instance.currentUser;
            
            // Navigate to onboarding screen with userId
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OnboardingScreen(
                  userId: currentUser?.uid,
                ),
              ),
            );
          }
        }
      } else {
        print('⏳ Waiting for email verification...');
      }
    } catch (e) {
      print('❌ Error checking verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    final result = await authService.sendEmailVerification();
    
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
        startResendCooldown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: const Color(0xFF1B4871),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await authService.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 100,
                color: Color(0xFF1B4871),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'We\'ve sent a verification link to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Please click the link in the email to verify your account.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Note: It may take 2-5 minutes for the email to arrive.',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              const CircularProgressIndicator(
                color: Color(0xFF1B4871),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Waiting for verification...',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Checking automatically every 3 seconds...',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              
              // Manual check button
              ElevatedButton.icon(
                onPressed: isChecking ? null : () async {
                  await checkEmailVerified();
                },
                icon: isChecking 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isChecking ? 'Checking...' : 'Check Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: canResendEmail ? resendVerificationEmail : null,
                icon: const Icon(Icons.email),
                label: Text(
                  canResendEmail 
                      ? 'Resend Email' 
                      : 'Resend in ${resendCooldown}s',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4871),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () async {
                  await authService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: Color(0xFF1B4871),
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
}