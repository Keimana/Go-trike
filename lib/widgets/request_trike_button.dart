import 'package:flutter/material.dart';
import 'timer_modal.dart'; // <-- Group53

class RequestTrikeModal extends StatelessWidget {
  const RequestTrikeModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600, // adjust if needed
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          // Title
          const Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Text(
              "Request a Trike",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Button
          Positioned(
            left: 12,
            right: 12,
            bottom: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0097B2),
                minimumSize: const Size(366, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // close bottom modal
                showDialog(
                  context: context,
                  barrierDismissible: false, // prevent closing by tap outside
                  builder: (context) => const TimerModal(), // popup in center
                );
              },
              child: const Text(
                'Request a Ride',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
