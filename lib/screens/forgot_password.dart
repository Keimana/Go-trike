import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter your email to reset password",
                style: TextStyle(fontFamily: 'Roboto', fontSize: 16)),
            const SizedBox(height: 20),
            CustomTextField(hintText: "Email", controller: emailController),
            const SizedBox(height: 18),
            PrimaryButton(text: "Send Reset Link", onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
