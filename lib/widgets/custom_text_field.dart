import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        color: Color(0xFF323232),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: Color(0xFF323232),
        ),
        filled: true,
        fillColor: const Color(0xFFF2F4F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
