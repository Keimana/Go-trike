import 'package:flutter/material.dart';
import '../screens/home_page.dart'; // Import your HomePage screen

void showDriverOnWayModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          width: 327,
          height: 316,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Driver Image
              Positioned(
                top: 27,
                child: SizedBox(
                  width: 80,
                  height: 75,
                  child: Image.asset(
                    'assets/images/trike.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Title Text
              const Positioned(
                top: 146,
                child: Text(
                  'Driver is in your way!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Subtitle Text
              const Positioned(
                top: 180,
                child: Text(
                  'Please wait for your driver...',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Button
              Positioned(
                top: 224,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close modal
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0097B2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Text(
                      'OK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
