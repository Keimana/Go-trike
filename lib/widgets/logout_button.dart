import 'package:flutter/material.dart';
import '../screens/signin_screen.dart';

class LogoutButton extends StatelessWidget {
  final double width;
  final double height;

  const LogoutButton({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      },
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFF5744)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Logout',
          style: TextStyle(
            fontSize: width * 0.04,
            color: const Color(0xFFFF5744),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
