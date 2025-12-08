import 'package:flutter/material.dart';
import '../screens/signin_screen.dart'; // ✅ adjust path if needed

class SignupEmailVerify extends StatelessWidget {
  const SignupEmailVerify({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 434,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            SizedBox(
              height: 120,
              child: Image.asset(
                'assets/images/trike.png',
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Verify your Account",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            const Text(
              "We’ve sent the email verification to your email account.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please check your email account.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),

            // Resend Button
            SizedBox(
              width: 270,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Handle resend verification
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4871),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Resend Email Verification",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Button
            SizedBox(
              width: 270,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  // Close modal then go to SignInScreen
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignInScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4871),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "I’ve got the link!",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Support Text
            const Text(
              "Question? Email here Gotrike147@gmail.com",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
