import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/primary_button.dart';

class TerminalModalAccept extends StatefulWidget {
  const TerminalModalAccept({super.key});

  @override
  State<TerminalModalAccept> createState() => _TerminalModalAcceptState();
}

class _TerminalModalAcceptState extends State<TerminalModalAccept> {
  final TextEditingController todaController = TextEditingController();

  @override
  void dispose() {
    todaController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final todaNumber = todaController.text.trim();

    // Check if empty
    if (todaNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter TODA Number")),
      );
      return;
    }

    // Check if digits only
    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(todaNumber);
    if (!isDigitsOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("TODA Number must contain digits only")),
      );
      return;
    }

    // Return the TODA number to the caller
    Navigator.pop(context, todaNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 5,
      backgroundColor: Colors.white,
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

            const Text(
              'Enter TODA Number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Number-only TextField
            TextField(
              controller: todaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                hintText: "TODA Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    side: const BorderSide(color: Color(0xFF0097B2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Color(0xFF0097B2),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

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