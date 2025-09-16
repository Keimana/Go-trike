import 'package:flutter/material.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_button.dart';
import '../widgets/timer_modal.dart';
import 'activity_logs_screen.dart';
import 'account_settings_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

    // Safe top padding (status bar)
    final safeTop = MediaQuery.of(context).padding.top;

    final buttonWidth = w * 0.65;
    const buttonHeight = 60.0;

    /// Tight bounds
    final LatLngBounds telabastaganBounds = LatLngBounds(
      southwest: const LatLng(15.1140, 120.6125),
      northeast: const LatLng(15.1195, 120.6185),
    );

    return Stack(
      children: [

        /// Google Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(15.116888, 120.615710),
            zoom: 16.0, 
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          cameraTargetBounds: CameraTargetBounds(telabastaganBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(16, 20),
        ),

        /// Settings Button
        Positioned(
          top: safeTop + 16, // 16 pixels below the status bar
          right: w * 0.04,
          child: SettingsButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsButton(),
                ),
              );
            },
          ),
        ),

        /// Request Trike Button (center-bottom)
        Positioned(
          bottom: h * 0.15,
          left: (w - buttonWidth) / 2,
          child: GestureDetector(
            onTap: () {
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
