import 'package:flutter/material.dart';
import 'screens - admin/signin_admin.dart';
import 'screens - admin/dashboard_admin.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (context) => const SignInAdmin(),
        "/adminDashboard": (context) => const UiAdminSideReports(),
      },
    );
  }
}
