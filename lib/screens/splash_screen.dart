import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/onboarding_service.dart';
import '../screens/home_page.dart';
import '../onboarding/onboarding_screen.dart';
import '../screens/signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    // Add a small delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user has seen onboarding
    final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
    
    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(userId: currentUser?.uid),
        ),
      );
    } else if (currentUser != null && currentUser.emailVerified) {
      // Returning user who is logged in and verified - go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Returning user who is not logged in - go to sign in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/trike.png',
              height: 200,
            ),
            const SizedBox(height: 30),
            
            // App Name
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Go ',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4871),
                    ),
                  ),
                  TextSpan(
                    text: 'Trike',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEAAD39),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4871)),
            ),
          ],
        ),
      ),
    );
  }
}