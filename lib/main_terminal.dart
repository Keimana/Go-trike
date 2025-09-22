import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens - terminal/signin_screen_terminal.dart';
import 'screens - terminal/home_terminal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TerminalApp());
}

class TerminalApp extends StatelessWidget {
  const TerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Trike Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SignInScreenTerminal(),
            );
          case '/home':
            final terminalName = settings.arguments as String? ?? 'Terminal 1';
            return MaterialPageRoute(
              builder: (_) => TerminalHome(terminalName: terminalName),
            );
        }
        return null;
      },
    );
  }
}
