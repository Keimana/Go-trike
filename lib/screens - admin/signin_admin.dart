import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isLoading = false;

  void handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      print('✅ Admin signed in: ${userCredential.user?.uid}');
      
      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/adminDashboard");
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      
      if (e.code == 'user-not-found') {
        message = "No admin account found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format";
      } else if (e.code == 'user-disabled') {
        message = "This account has been disabled";
      } else {
        message = "Login failed: ${e.message}";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Roboto",
                          ),
                          children: [
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
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : PrimaryButton(
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