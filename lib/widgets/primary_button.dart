import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 182, // fixed width
      height: 40, // fixed height
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0097B2), // brand blue
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // corner radius
          ),
          // remove padding so height stays exactly 40
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
