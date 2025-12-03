import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../screens/home_page.dart';

class OnboardingScreen extends StatefulWidget {
  final String? userId; // true = show after login

  const OnboardingScreen({this.userId, Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  // Onboarding pages with custom height and padding
  final List<Map<String, dynamic>> onboardingPages = [
    {
      "image": "assets/images/trike.png",
      "title": "Welcome!",
      "desc": "Go Trike App",
      "height": 300.0,
      "padding": const EdgeInsets.only(top: 50),
    },
    {
      "image": "assets/images/onboard2.png",
      "title": "Book a Ride",
      "desc": "Select pickup and wait for driver",
      "height": 280.0,
      "padding": EdgeInsets.zero,
    },
    {
      "image": "assets/images/onboard3.png",
      "title": "Ride History",
      "desc": "Select your drop-off",
      "height": 280.0,
      "padding": EdgeInsets.zero,
    },
    {
      "image": "assets/images/onboard4.png",
      "title": "Payment Method",
      "desc": "Select payment method (Cash or GCash)",
      "height": 280.0,
      "padding": EdgeInsets.zero,
    },
    {
      "image": "assets/images/onboard5.png",
      "title": "Wait a Driver",
      "desc": "Wait for a driver to pick you up",
      "height": 280.0,
      "padding": EdgeInsets.zero,
    },
    {
      "image": "assets/images/onboard6.png",
      "title": "Account Settings",
      "desc": "This is your account settings",
      "height": 280.0,
      "padding": EdgeInsets.zero,
    },
    {
      "image": "assets/images/onboard7.png",
      "title": "have a great day!",
      "desc": "Enjoy Riding!",
      "height": 280.0,
      "padding": EdgeInsets.zero,
    },
  ];

  void finishOnboarding() {
    if (widget.userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView with dynamic pages
          PageView.builder(
            controller: _controller,
            itemCount: onboardingPages.length,
            onPageChanged: (index) =>
                setState(() => isLastPage = index == onboardingPages.length - 1),
            itemBuilder: (context, index) {
              final page = onboardingPages[index];
              return buildPage(page, index: index); // pass the index here
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SmoothPageIndicator dots
                SmoothPageIndicator(
                  controller: _controller,
                  count: onboardingPages.length,
                  effect: const WormEffect(
                      dotHeight: 10, dotWidth: 10, activeDotColor: Colors.blue),
                ),
                const SizedBox(height: 20),

                // Buttons row: Back | Skip | Next/Done
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        if (_controller.page! > 0) {
                          _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        }
                      },
                      child: Text(
                        "Back",
                        style: TextStyle(
                          fontSize: 17,
                          color: (_controller.hasClients && _controller.page! > 0)
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),

                    // Skip button (center)
                    GestureDetector(
                      onTap: finishOnboarding,
                      child: const Text(
                        "Skip",
                        style: TextStyle(fontSize: 17, color: Colors.grey),
                      ),
                    ),

                    // Next / Done button
                    GestureDetector(
                      onTap: () {
                        if (isLastPage) {
                          finishOnboarding();
                        } else {
                          _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        }
                      },
                      child: Text(
                        isLastPage ? "Done" : "Next",
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget buildPage(Map<String, dynamic> page, {required int index}) {
  return SingleChildScrollView(
    padding: page['padding'] ?? const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Only show "Go Trike" on the first page
        if (index == 0)
          Column(
            children: const [
              SizedBox(height: 60), // top spacing
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Go ',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0097B2),
                      ),
                    ),
                    TextSpan(
                      text: 'Trike',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9500),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 70),
            ],
          ),

        // Top spacing for pages 2–7
        if (index != 0)
          const SizedBox(height: 150), // adjust height as needed

        // Image
        Image.asset(page['image'], height: page['height'] ?? 280),
        const SizedBox(height: 80),

        // Title above description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            page['title'],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            page['desc'],
            style: const TextStyle(fontSize: 17, color: Colors.black54, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

}
