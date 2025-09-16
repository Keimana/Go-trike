import 'package:flutter/material.dart';
import '../widgets/card_builder_passenger_terminal.dart';
import 'terminal_modal_accept.dart'; // ✅ import your accept modal

class TerminalRequestTrikeModal extends StatefulWidget {
  const TerminalRequestTrikeModal({super.key});

  @override
  State<TerminalRequestTrikeModal> createState() =>
      _TerminalRequestTrikeModalState();
}

class _TerminalRequestTrikeModalState extends State<TerminalRequestTrikeModal>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            width: screenWidth,
            height: screenHeight * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header line
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF323232),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Passenger Request List
                Expanded(
                  child: ListView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return CardBuilderPassengerTerminal(
                        name: "Ronan",
                        fare: "₱140.00",
                        paymentMethod: "Cash",
                        address: "Lorem ipsum Street, Pampanga, Manila",
                        onAccept: () {
                          // ✅ Open TODA Number modal
                          showDialog(
                            context: context,
                            builder: (context) => const TerminalModalAccept(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
