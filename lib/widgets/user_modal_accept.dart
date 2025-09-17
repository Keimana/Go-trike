import 'package:flutter/material.dart';

class UserAcceptState extends StatefulWidget {
  const UserAcceptState({super.key});

  @override
  State<UserAcceptState> createState() => _UserAcceptStateState();
}

class _UserAcceptStateState extends State<UserAcceptState> {
  bool driverFound = false; // Example state variable

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 327,
        height: 316,
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
                  'assets/images/trike.png', // Correct way to reference local asset
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Title Text
            Positioned(
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
            Positioned(
              top: 180,
              child: Text(
                'Please wait your driver...',
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
                  setState(() {
                    driverFound = true; // Example action
                  });
                },
                child: Container(
                  width: 114,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0097B2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Text(
                    driverFound ? 'Driver Found!' : 'I found the Driver!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
