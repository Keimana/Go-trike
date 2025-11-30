// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../widgets/logout_button.dart'; // ✅ import your LogoutButton

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final cardWidth = w * 0.9;
    final cardHeight = h * 0.08;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Content in the center
          Center(
            child: Text(
              'Under Development',
              style: TextStyle(
                fontSize: w * 0.05,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ✅ Logout button at bottom center
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(bottom: h * 0.03),
                child: LogoutButton(
                  width: cardWidth,
                  height: cardHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
