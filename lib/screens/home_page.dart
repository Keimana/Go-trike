import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_button.dart';
import '../widgets/timer_modal.dart';
import 'activity_logs_screen.dart';
import 'account_settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MainScreenContent(),     // index 0 → Home
      const ActivityLogsScreen(),    // index 1 → Activity Logs
      const AccountSettingsScreen(), // index 2 → Account Settings
    ];

    return Scaffold(
      body: Stack(
        children: [
          pages[selectedIndex],
          BottomNavigationBarWidget(
            selectedIndex: selectedIndex,
            onTap: (index) => setState(() => selectedIndex = index),
          ),
        ],
      ),
    );
  }
}

class MainScreenContent extends StatelessWidget {
  const MainScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final buttonWidth = w * 0.65;
    const buttonHeight = 60.0;

    return Stack(
      children: [
        /// 🔹 Google Maps Placeholder (Full screen space)
        SizedBox(
          width: w,
          height: h,
          child: Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Text(
              "Google Maps API will render here",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
        ),

        /// 🔹 Settings Button (top-right)
        Positioned(
          top: h * 0.04,
          right: w * 0.04,
          child: const SettingsButton(),
        ),

        /// 🔹 Request Trike Button (center-bottom)
        Positioned(
          bottom: h * 0.15,
          left: (w - buttonWidth) / 2,
          child: GestureDetector(
            onTap: () {
              // Instead of modal bottom sheet (slides from bottom)
              // show a dialog in the center
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const TimerModal(),
              );
            },
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
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
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
