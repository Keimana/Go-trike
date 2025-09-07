import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/request_trike_button.dart'; // adjust to your real path

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _MainScreenMap(),
    );
  }
}

class _MainScreenMap extends StatelessWidget {
  const _MainScreenMap();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          // ───── Bottom nav background
          Positioned(
            left: w * 0.11,
            top: h * 0.87,
            child: Container(
              width: w * 0.78,
              height: h * 0.07,
              decoration: ShapeDecoration(
                color: const Color(0xFFF8FAFB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          // ───── Center nav oval
          Positioned(
            left: w * 0.19,
            top: h * 0.875,
            child: Container(
              width: w * 0.13,
              height: w * 0.13,
              decoration: const ShapeDecoration(
                color: Color(0xFF0097B2),
                shape: OvalBorder(),
              ),
            ),
          ),
          // center nav icon (home)
          Positioned(
            left: w * 0.22,
            top: h * 0.89,
            child: SizedBox(
              width: w * 0.07,
              height: w * 0.07,
              child: SvgPicture.asset(
                'assets/icons/home.svg',
                fit: BoxFit.contain,
                color: Colors.white,
              ),
            ),
          ),

          // ───── Middle nav oval
          Positioned(
            left: w * 0.43,
            top: h * 0.875,
            child: Container(
              width: w * 0.13,
              height: w * 0.13,
              decoration: const ShapeDecoration(
                color: Color(0xFFF8FAFB),
                shape: OvalBorder(),
              ),
            ),
          ),
          Positioned(
            left: w * 0.46,
            top: h * 0.89,
            child: SizedBox(
              width: w * 0.07,
              height: w * 0.07,
              child: SvgPicture.asset(
                'assets/icons/description.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ───── Right nav oval
          Positioned(
            left: w * 0.68,
            top: h * 0.875,
            child: Container(
              width: w * 0.13,
              height: w * 0.13,
              decoration: const ShapeDecoration(
                color: Color(0xFFF8FAFB),
                shape: OvalBorder(),
              ),
            ),
          ),
          Positioned(
            left: w * 0.71,
            top: h * 0.89,
            child: SizedBox(
              width: w * 0.07,
              height: w * 0.07,
              child: SvgPicture.asset(
                'assets/icons/person.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ───── Request Trike Button (centered horizontally)
          Positioned(
            top: h * 0.71,
            left: 0,
            right: 0,
            child: Center(
              child: RequestTrikeButton(
                onTap: () => debugPrint('Request Trike pressed!'),
              ),
            ),
          ),

          // ───── Title
          Positioned(
            left: w * 0.075,
            top: h * 0.05,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(
                      color: const Color(0xFF0097B2),
                      fontSize: w * 0.08,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'Trike',
                    style: TextStyle(
                      color: const Color(0xFFFF9500),
                      fontSize: w * 0.08,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // welcome text
          Positioned(
            left: w * 0.075,
            top: h * 0.15,
            child: SizedBox(
              width: w * 0.55,
              child: Text(
                'Welcome Back Camille!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.08,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // address
          Positioned(
            left: w * 0.13,
            top: h * 0.27,
            child: SizedBox(
              width: w * 0.8,
              child: Text(
                'Lorem ipsum Street, Pampanga, Manila',
                style: TextStyle(
                  color: const Color(0xFF323232),
                  fontSize: w * 0.04,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),

          // ───── Settings button (top-right)
          Positioned(
            right: w * 0.05,
            top: h * 0.05,
            child: GestureDetector(
              onTap: () => debugPrint('Settings pressed!'),
              child: Container(
                width: w * 0.15,
                height: w * 0.15,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF8FAFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/settings.svg',
                    width: w * 0.08,
                    height: w * 0.08,
                    fit: BoxFit.contain,
                    color: const Color(0xFF323232),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
