import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'terminal_modal_pickup.dart';

class TerminalModalAccept extends StatefulWidget {
  const TerminalModalAccept({super.key});

  @override
  State<TerminalModalAccept> createState() => _TerminalModalAcceptState();
}

class _TerminalModalAcceptState extends State<TerminalModalAccept> {
  final TextEditingController todaController = TextEditingController();

  void _onConfirm() {
    final todaNumber = todaController.text.trim();

    if (todaNumber.isEmpty) {
      // Show error if blank
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter TODA Number")),
      );
      return;
    }

    // ✅ Close this modal first
    Navigator.pop(context);

    // ✅ Open the pickup modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Dialog(
          insetPadding: EdgeInsets.all(20),
          backgroundColor: Colors.transparent,
          child: TerminalModalPickup(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top image
            Container(
              width: 80,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage("assets/images/trike.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Enter TODA Number',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // TODA Number input (using CustomTextField)
            CustomTextField(
              hintText: "TODA Number",
              controller: todaController,
            ),

            const SizedBox(height: 30),

            // Buttons Row
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      side: const BorderSide(color: Color(0xFF0097B2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Color(0xFF0097B2),
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12), // spacing between buttons

                  // Confirm button (fixed size, not expanded)
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: PrimaryButton(
                      text: "Confirm",
                      onPressed: _onConfirm,
                    ),
                  ),
                ],
              ),

          ],
        ),
      ),
    );
  }
}
