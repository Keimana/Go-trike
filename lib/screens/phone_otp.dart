import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'signin_screen.dart';

final authService = AuthService();

class PhoneOTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String userId;

  const PhoneOTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.userId,
  });

  @override
  State<PhoneOTPVerificationScreen> createState() => _PhoneOTPVerificationScreenState();
}

class _PhoneOTPVerificationScreenState extends State<PhoneOTPVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  bool isVerifying = false;
  bool canResend = false;
  int resendCooldown = 60;
  Timer? cooldownTimer;
  String? errorMessage;
  bool otpSent = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  void _sendOTP() {
    setState(() {
      otpSent = false;
      errorMessage = null;
    });

    authService.sendOTP(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          otpSent = true;
        });
        _startResendCooldown();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your phone!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onError: (error) {
        setState(() {
          errorMessage = error;
          otpSent = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onAutoVerified: () {
        // Auto-verified (Android only sometimes)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified automatically!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      },
    );
  }

  void _startResendCooldown() {
    setState(() {
      canResend = false;
      resendCooldown = 60;
    });

    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown > 0) {
        setState(() {
          resendCooldown--;
        });
      } else {
        setState(() {
          canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    // Get OTP code from all text fields
    String otpCode = otpControllers.map((controller) => controller.text).join();

    if (otpCode.length != 6) {
      setState(() {
        errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    setState(() {
      isVerifying = true;
      errorMessage = null;
    });

    final result = await authService.verifyOTP(otpCode);

    setState(() {
      isVerifying = false;
    });

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      setState(() {
        errorMessage = result['message'];
      });
      
      // Clear OTP fields on error
      for (var controller in otpControllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
    }
  }

  void _resendOTP() {
    if (!canResend) return;

    // Clear all OTP fields
    for (var controller in otpControllers) {
      controller.clear();
    }

    _sendOTP();
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: const Color(0xFF0097B2),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              const Icon(
                Icons.phone_android,
                size: 80,
                color: Color(0xFF0097B2),
              ),
              const SizedBox(height: 24),

              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a 6-digit code to',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 4),
              
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0097B2),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0097B2),
                            width: 3,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          // Move to next field
                          focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          // Move to previous field
                          focusNodes[index - 1].requestFocus();
                        }

                        // Auto-verify when all 6 digits entered
                        if (index == 5 && value.length == 1) {
                          _verifyOTP();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Error message
              if (errorMessage != null)
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
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097B2),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend OTP
              TextButton(
                onPressed: canResend ? _resendOTP : null,
                child: Text(
                  canResend
                      ? 'Resend OTP'
                      : 'Resend OTP in ${resendCooldown}s',
                  style: TextStyle(
                    color: canResend ? const Color(0xFF0097B2) : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),

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
                    color: Color(0xFF0097B2),
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