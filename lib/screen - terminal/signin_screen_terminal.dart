import 'package:flutter/material.dart';
import '../screen - terminal/home_terminal.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart'; //import your CustomTextField

class SignInScreenTerminal extends StatefulWidget {
  const SignInScreenTerminal({super.key});

  @override
  State<SignInScreenTerminal> createState() => _SignInScreenTerminalState();
}

class _SignInScreenTerminalState extends State<SignInScreenTerminal> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : size.width * 0.9,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Logo
                SizedBox(
                  height: size.height * 0.25,
                  child: Image.asset(
                    "assets/images/trike.png",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                //App Name
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Go',
                        style: TextStyle(
                          color: Color(0xFF0097B2),
                          fontSize: 32,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(
                        text: 'Trike',
                        style: TextStyle(
                          color: Color(0xFFFF9500),
                          fontSize: 32,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                //Title
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

                //Email Field
                CustomTextField(
                  hintText: "Email",
                  controller: emailController,
                ),

                const SizedBox(height: 20),

                //Password Field
                CustomTextField(
                  hintText: "Password",
                  controller: passwordController,
                  obscureText: true,
                ),

                const SizedBox(height: 30),

                //Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: PrimaryButton(
                    text: "Login",
                    onPressed: () {
                      // For now, just navigate to TerminalHome
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TerminalHome(),
                        ),
                      );
                    },
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
