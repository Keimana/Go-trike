import 'package:flutter/material.dart';
import '../widgets/card_builder_passenger_terminal.dart';
import 'terminal_modal_accept.dart'; //  import your accept modal

class TerminalRequestTrikeModal extends StatefulWidget {
  const TerminalRequestTrikeModal({super.key});

  @override
  State<TerminalRequestTrikeModal> createState() =>
      _TerminalRequestTrikeModalState();
}

class _TerminalRequestTrikeModalState extends State<TerminalRequestTrikeModal>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  //  Passenger list (sample data)
  List<Map<String, String>> passengers = [
    {
      "name": "Ronan",
      "fare": "₱140.00",
      "payment": "Cash",
      "address": "Lorem ipsum Street, Pampanga, Manila",
      "pickup": "SM City Pampanga",
      "dropoff": "Manila Central Terminal",
    },
    {
      "name": "Angela",
      "fare": "₱95.00",
      "payment": "GCash",
      "address": "San Fernando, Pampanga",
      "pickup": "WalterMart",
      "dropoff": "Angeles Terminal",
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => _isVisible = true);
    });
  }

  void _deletePassenger(int index) {
    setState(() {
      passengers.removeAt(index);
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
                  child: passengers.isEmpty
                      ? const Center(
                          child: Text(
                            "No passenger requests",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: passengers.length,
                          itemBuilder: (context, index) {
                            final p = passengers[index];
                            return CardBuilderPassengerTerminal(
                              name: p["name"]!,
                              fare: p["fare"]!,
                              paymentMethod: p["payment"]!,
                              address: p["address"]!,
                              pickUpLocation: p["pickup"]!,
                              dropOffLocation: p["dropoff"]!,
                              onAccept: () {
                                //  Open TODA Number modal
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const TerminalModalAccept(),
                                );
                              },
                              onCancel: () => _deletePassenger(index), // 
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
