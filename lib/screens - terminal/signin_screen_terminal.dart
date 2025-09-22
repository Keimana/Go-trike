import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';

class SignInScreenTerminal extends StatefulWidget {
  const SignInScreenTerminal({super.key});

  @override
  State<SignInScreenTerminal> createState() => _SignInScreenTerminalState();
}

class _SignInScreenTerminalState extends State<SignInScreenTerminal> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _loginTerminal() async {
    setState(() => _isLoading = true);

    try {
      // 🔹 1. Sign in with FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 🔹 2. Fetch terminal data from Firestore
      DocumentSnapshot terminalDoc =
          await FirebaseFirestore.instance.collection('terminals').doc(uid).get();

      if (!terminalDoc.exists) {
        throw Exception("Terminal data not found in Firestore");
      }

      String terminalName = terminalDoc['terminalName'];

      // 🔹 3. Navigate to Home with terminalName
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: terminalName,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : size.width * 0.9,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  height: size.height * 0.25,
                  child: Image.asset(
                    "assets/images/trike.png",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Representative Login',
                  style: TextStyle(
                    color: Color(0xFF323232),
                    fontSize: 26,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 30),

                // Email Field
                CustomTextField(
                  hintText: "Email",
                  controller: emailController,
                ),

                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  hintText: "Password",
                  controller: passwordController,
                  obscureText: true,
                ),

                const SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: PrimaryButton(
                    text: _isLoading ? "Logging in..." : "Login",
                    onPressed: _isLoading ? null : _loginTerminal,
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
