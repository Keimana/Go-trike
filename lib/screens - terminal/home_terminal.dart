import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/primary_button.dart';
import '../widgets/terminal_request_trike_modal.dart';

class TerminalHome extends StatelessWidget {
  final String terminalName; // 👈 dynamic terminal name

  const TerminalHome({
    super.key,
    this.terminalName = 'Terminal 1', // 👈 default value (Fix 1)
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  terminalName, // 👈 shows correct terminal
                  style: const TextStyle(
                    color: Color(0xFF323232),
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Ride Request Button
            SizedBox(
              width: 208,
              height: 61,
              child: PrimaryButton(
                text: "Ride Request",
                icon: SvgPicture.asset(
                  "assets/icons/person_search.svg",
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TerminalRequestTrikeModal(),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
