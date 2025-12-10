import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_page.dart';
import '../screens/signin_screen.dart';
import '../onboarding/onboarding_screen.dart';

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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _navigateToSignIn();
        return;
      }

      await currentUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      
      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _navigateToSignIn();
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _navigateToSignIn();
        return;
      }

      final userData = userDoc.data();
      final hasCompletedOnboarding = userData?['onboardingCompleted'] ?? false;

      if (!hasCompletedOnboarding) {
        _navigateToOnboarding(refreshedUser.uid);
        return;
      }

      _navigateToHome();

    } catch (e) {
      debugPrint('Error in splash screen: $e');
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _navigateToSignIn();
    }
  }

  void _navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _navigateToOnboarding(String userId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(userId: userId),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/trike.png',
              height: 200,
            ),
            const SizedBox(height: 30),
            
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
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4871)),
            ),
          ],
        ),
      ),
    );
  }
}