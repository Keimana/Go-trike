import 'package:flutter/material.dart';

/// A rounded "Request Trike" call-to-action button.
/// It keeps the exact styling from the design file.
class RequestTrikeButton extends StatelessWidget {
  final VoidCallback onTap;

  const RequestTrikeButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 268,
        height: 60,
        decoration: ShapeDecoration(
          color: const Color(0xFF0097B2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Request Trike',
          style: TextStyle(
            color: Color(0xFFF0F0F0),
            fontSize: 20,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
