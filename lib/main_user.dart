import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Remove duplicate
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/home_page.dart';
import 'screens/edit_profile.dart';
import 'screens/help.dart';
import 'screens/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
// Add this line to ensure Firestore is properly initialized
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
      // first screen to open
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInScreen(),
        '/signin': (context) => const HomePage(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot': (context) => ForgotPasswordScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/help': (context) => const HelpScreen(),

      },
    );
  }
}
