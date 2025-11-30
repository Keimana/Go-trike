import 'package:flutter/material.dart';
import '../widgets/primary_button.dart'; // adjust path if needed

class TerminalModalPickup extends StatelessWidget {
  const TerminalModalPickup({super.key});

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Center(
    child: Container(
      width: screenWidth * 0.9, // responsive width
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trike Image
          SizedBox(
            height: screenHeight * 0.15,
            child: Image.asset(
              "assets/images/trike.png",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),

          // Message
          const Text(
            'Please Pick up your Passenger',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          // New Text
          const Text(
            'Next tricycle driver from the line',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 30),

          // Primary Button
          PrimaryButton(
            text: "Okay!",
            onPressed: () {
              Navigator.pop(context); // close modal
            },
          ),
        ],
      ),
    ),
  );
}

}
