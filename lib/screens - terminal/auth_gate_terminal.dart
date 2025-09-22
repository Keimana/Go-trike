import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_terminal.dart';
import 'signin_screen_terminal.dart';

final Map<String, String> terminalAccounts = {
  "terminal1@gmail.com": "Terminal 1",
  "terminal2@gmail.com": "Terminal 2",
  "terminal3@gmail.com": "Terminal 3",
  "terminal4@gmail.com": "Terminal 4",
  "terminal5@gmail.com": "Terminal 5",
};

class AuthGateTerminal extends StatelessWidget {
  const AuthGateTerminal({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const SignInScreenTerminal(); // your login screen
        }

        final email = snapshot.data!.email ?? "";
        final terminalName = terminalAccounts[email];

        if (terminalName == null) {
          return const Scaffold(
            body: Center(child: Text("Unauthorized account")),
          );
        }

        return TerminalHome(terminalName: terminalName);
      },
    );
  }
}
