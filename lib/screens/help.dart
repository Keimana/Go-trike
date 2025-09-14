// lib/screens/help.dart
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Center(
        child: Text(
          'This is the Help page',
          style: TextStyle(
            fontSize: w * 0.05,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
