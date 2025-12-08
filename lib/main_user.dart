import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/home_page.dart';
import 'screens/edit_profile.dart';
import 'screens/help.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Ensure Firestore is properly initialized
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const GoTrikeApp());
}

class GoTrikeApp extends StatelessWidget {
  const GoTrikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Trike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0097B2)),
      ),
      // CHANGE: Start with splash screen instead of signin
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // CHANGED FROM SignInScreen
        '/signin': (context) => const SignInScreen(), // FIXED - was pointing to HomePage
        '/home': (context) => const HomePage(), // ADD THIS
        '/signup': (context) => const SignUpScreen(),
        '/forgot': (context) => ForgotPasswordScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}