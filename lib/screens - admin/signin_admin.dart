import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';

class SignInAdmin extends StatefulWidget {
  const SignInAdmin({super.key});

  @override
  State<SignInAdmin> createState() => _SignInAdminState();
}

class _SignInAdminState extends State<SignInAdmin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleLogin() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email == "admin@example.com" && password == "12345") {
      Navigator.pushReplacementNamed(context, "/adminDashboard");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // LEFT SIDE (Illustration + Logo)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trike illustration
                      Image.asset(
                        "assets/images/trike.png",
                        width: constraints.maxWidth * 0.25,
                        height: constraints.maxHeight * 0.35,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 40),

                      // Go Trike Branding
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Roboto",
                          ),
                          children: const [
                            TextSpan(text: "Go", style: TextStyle(color: Color(0xFF0097B2))),
                            TextSpan(text: " ", style: TextStyle(color: Color(0xFF34C759))),
                            TextSpan(text: "Trike", style: TextStyle(color: Color(0xFFFF9500))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // RIGHT SIDE (Login Form)
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFB),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo (trike again small on top)
                        Image.asset(
                          "assets/images/trike.png",
                          height: 120,
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Admin Dashboard",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Roboto",
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Email Input
                        CustomTextField(
                          hintText: "Email",
                          controller: emailController,
                        ),
                        const SizedBox(height: 20),

                        // Password Input
                        CustomTextField(
                          hintText: "Password",
                          controller: passwordController,
                          obscureText: true,
                        ),
                        const SizedBox(height: 30),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: PrimaryButton(
                            text: "Login",
                            onPressed: handleLogin,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
