import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_page.dart'; // <-- import your home page

class SignInScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Go Trike title
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
              ),
              const SizedBox(height: 16),

              // Logo
              Image.asset('assets/images/trike.png', height: 100),
              const SizedBox(height: 16),

              const Text(
                "Hello!",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Email input
              CustomTextField(
                hintText: "Email",
                controller: emailController,
              ),
              const SizedBox(height: 12),

              // Password input
              CustomTextField(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 18),

              // Login button
              PrimaryButton(
                text: "Login",
                onPressed: () {
                  // Directly navigate to HomePage without validation
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Forgot password
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/forgot'),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Color(0xFF0097B2),
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF0097B2),
                      ),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: Color(0xFF000000),
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
    );
  }
}
