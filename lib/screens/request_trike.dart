import 'package:flutter/material.dart';

class RequestTrikePage extends StatelessWidget {
  const RequestTrikePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          _MainScreenMap(),
        ],
      ),
    );
  }
}

class _MainScreenMap extends StatelessWidget {
  const _MainScreenMap();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 412,
          height: 917,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              // Bottom rounded bar
              Positioned(
                left: 46,
                top: 803,
                child: Container(
                  width: 320,
                  height: 62,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF8FAFB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              // Main oval for bottom bar
              Positioned(
                left: 77,
                top: 807,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF0097B2),
                    shape: OvalBorder(),
                  ),
                ),
              ),

              // Request Trike Button (blue pill)
              Positioned(
                left: 72,
                top: 655,
                child: Container(
                  width: 268,
                  height: 60,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF0097B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 72,
                top: 669.67,
                child: SizedBox(
                  width: 268,
                  height: 30.67,
                  child: Text(
                    'Request Trike',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Title GoTrike
              const Positioned(
                left: 31,
                top: 46,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Go',
                        style: TextStyle(
                          color: Color(0xFF0097B2),
                          fontSize: 32,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' '),
                      TextSpan(
                        text: 'Trike',
                        style: TextStyle(
                          color: Color(0xFFFF9500),
                          fontSize: 32,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Welcome Text
              const Positioned(
                left: 31,
                top: 136,
                child: SizedBox(
                  width: 224,
                  child: Text(
                    'Welcome Back Camille!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 33,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Address text
              const Positioned(
                left: 55,
                top: 244,
                child: SizedBox(
                  width: 330,
                  height: 24,
                  child: Text(
                    'Lorem ipsum Street, Pampanga, Manila',
                    style: TextStyle(
                      color: Color(0xFF323232),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              // Overlay for request dialog
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 412,
                  height: 917,
                  decoration: const BoxDecoration(color: Color(0xB2323232)),
                ),
              ),

              // Bottom card with fare + payment
              Positioned(
                left: 0,
                top: 428,
                child: Container(
                  width: 412,
                  height: 489,
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Fare Amount Field
              Positioned(
                left: 31,
                top: 571,
                child: Container(
                  width: 349,
                  height: 60,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF2F4F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 50,
                top: 585,
                child: SizedBox(
                  width: 147,
                  child: Text(
                    'Fare Amount',
                    style: TextStyle(
                      color: Color(0xFF323232),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 28,
                top: 529,
                child: Text(
                  'How much will you pay?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Payment Section
              const Positioned(
                left: 28,
                top: 661,
                child: Text(
                  'Payment Method',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Cash button
              Positioned(
                left: 28,
                top: 709,
                child: Container(
                  width: 113,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF0097B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 28,
                top: 718,
                child: SizedBox(
                  width: 113,
                  child: Text(
                    'Cash',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              // Gcash button
              Positioned(
                left: 162,
                top: 709,
                child: Container(
                  width: 113,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0xFF0097B2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 162,
                top: 718,
                child: SizedBox(
                  width: 113,
                  child: Text(
                    'Gcash',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0097B2),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              // Request & Cancel Buttons
              Positioned(
                left: 12,
                top: 787,
                child: Container(
                  width: 189,
                  height: 60,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF0097B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 12,
                top: 800,
                child: SizedBox(
                  width: 188,
                  child: Text(
                    'Request a Ride',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 212,
                top: 787,
                child: Container(
                  width: 189,
                  height: 60,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0xFF0097B2)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 212,
                top: 800,
                child: SizedBox(
                  width: 188,
                  child: Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0097B2),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
