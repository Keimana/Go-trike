// lib/widgets/settings_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/settings_screen.dart';

class SettingsButton extends StatelessWidget {
  /// Optional: if not provided, tapping will open SettingsScreen by default
  final VoidCallback? onTap;

  const SettingsButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final buttonSize = w * 0.15;
    const cornerRadius = 20.0;

    return Material(
      color: const Color(0xFFF8FAFB),
      borderRadius: BorderRadius.circular(cornerRadius),
      elevation: 2, // keeps subtle shadow
      child: InkWell(
        borderRadius: BorderRadius.circular(cornerRadius),
        onTap: onTap ??
            () {
              // Default navigation to SettingsScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/settings.svg',
              width: buttonSize * 0.5,
              height: buttonSize * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
