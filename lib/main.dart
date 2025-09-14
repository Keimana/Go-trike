import 'package:flutter/material.dart';
import 'User - Screens/signin_screen.dart';
import 'User - Screens/signup_screen.dart';
import 'User - Screens/forgot_password.dart';
import 'User - Screens/home_page.dart';
import 'User - Screens/help.dart';
import 'User - Screens/edit_profile.dart';

void main() {
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
      // First screen to open
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot': (context) => ForgotPasswordScreen(),
        '/home': (context) => const HomePage(),
        '/help': (context) => const HelpScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}
