import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class SignUpScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Go Trike Title
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Go ',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0097B2),
                        ),
                      ),
                      TextSpan(
                        text: 'Trike',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Form fields
                CustomTextField(hintText: "Name", controller: nameController),
                const SizedBox(height: 12),
                CustomTextField(hintText: "Phone Number", controller: phoneController),
                const SizedBox(height: 12),
                CustomTextField(hintText: "Email", controller: emailController),
                const SizedBox(height: 12),
                CustomTextField(
                    hintText: "Password", obscureText: true, controller: passwordController),
                const SizedBox(height: 12),
                CustomTextField(
                    hintText: "Confirm Password", obscureText: true, controller: confirmController),
                const SizedBox(height: 18),

                // Sign Up button
                PrimaryButton(
                  text: "Sign Up",
                  onPressed: () {
                    // TODO: Implement sign-up logic
                  },
                ),
                const SizedBox(height: 20),

                // Sign In link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Color(0xFF0097B2),
                        ),
                        children: [
                          TextSpan(text: "Have an account? "),
                          TextSpan(
                            text: "Sign In",
                            style: TextStyle(
                              color: Color(0xFF000000), // black underline
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
