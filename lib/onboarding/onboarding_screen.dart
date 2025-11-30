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

  // Add all your pages here
  final List<Map<String, String>> onboardingPages = [
    {
      "image": "assets/images/trike.png", 
      "title": "Welcome!", 
      "desc": "Go Trike App"
      },
    {
      "image": "assets/images/onboard2.png", 
      "title": "Book a Ride", 
      "desc": "Select pickup and wait for driver"
      },
    {
      "image": "assets/images/onboard3.png", 
      "title": "Ride History", 
      "desc": "Select your drop-off"
    },
    {
      "image": "assets/images/onboard4.png", 
      "title": "Payment Method", 
      "desc": "Select payment method (Cash or GCash)"
    },
    {
      "image": "assets/images/onboard5.png", 
      "title": "Wait a Driver", 
      "desc": "Wait for a driver to pick you up"
    },
    {
      "image": "assets/images/onboard6.png", 
      "title": "Account Settings", 
      "desc": "This is your account settings"
    },
        {
      "image": "assets/images/onboard7.png", 
      "title": "Hoping for you to have a great day!", 
      "desc": "Enjoy Riding!"
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
            onPageChanged: (index) => setState(() => isLastPage = index == onboardingPages.length - 1),
            itemBuilder: (context, index) {
              final page = onboardingPages[index];
              return buildPage(
                image: page["image"]!,
                title: page["title"]!,
                desc: page["desc"]!,
              );
            },
          ),

          // Bottom controls
          // Bottom controls including dots and buttons
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SmoothPageIndicator dots
                SmoothPageIndicator(
                  controller: _controller,
                  count: onboardingPages.length,
                  effect: const WormEffect(dotHeight: 10, dotWidth: 10, activeDotColor: Colors.blue),
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

  Widget buildPage({required String image, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 280),
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text(desc, style: const TextStyle(fontSize: 17, color: Colors.black54), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
