import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/signin_screen.dart';

class LogoutButton extends StatelessWidget {
  final double width;
  final double height;

  const LogoutButton({
    super.key,
    required this.width,
    required this.height,
  });

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleLogout(context),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFF5744)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Logout',
          style: TextStyle(
            fontSize: width * 0.04,
            color: const Color(0xFFFF5744),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
