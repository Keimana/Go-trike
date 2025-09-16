import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../widgets/history_card_builder.dart';
import 'settings_screen.dart';
import 'report_toda_screen.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  // Mock data grouped by date
  final Map<String, List<Map<String, String>>> logsByDate = const {
    "Today": [
      {
        "title": "Go Trike",
        "price": "₱140.00",
        "subtitle": "4.15pm | 11 min",
        "toda": "Toda #13",
        "pickup": "Terminal 3",
      },
      {
        "title": "Go Trike",
        "price": "₱80.00",
        "subtitle": "2.45pm | 8 min",
        "toda": "Toda #7",
        "pickup": "Terminal 1",
      },
    ],
    "Yesterday": [
      {
        "title": "Go Trike",
        "price": "₱120.00",
        "subtitle": "3.30pm | 10 min",
        "toda": "Toda #5",
        "pickup": "Terminal 2",
      },
    ],
    "Past Month": [
      {
        "title": "Go Trike",
        "price": "₱90.00",
        "subtitle": "May 5 | 12 min",
        "toda": "Toda #2",
        "pickup": "Terminal 5",
      },
      {
        "title": "Go Trike",
        "price": "₱150.00",
        "subtitle": "May 12 | 15 min",
        "toda": "Toda #9",
        "pickup": "Terminal 4",
      },
    ],

  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: h * 0.12), // space for floating button

                          // Screen title
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                            child: const Text(
                              'Activity Logs',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.02),

                          // Logs grouped by date
                          ...logsByDate.entries.map((entry) {
                            final sectionTitle = entry.key;
                            final logs = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section title aligned with cards
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                                  child: Text(
                                    sectionTitle,
                                    style: TextStyle(
                                      fontSize: w * 0.045,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                SizedBox(height: h * 0.008),

                                      // Divider with less width and padding
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.01),
                                        child: Container(
                                          width: w * 0.9, // less than full width
                                          height: 0.5,
                                          decoration: const ShapeDecoration(
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(
                                                width: 0.5,
                                                strokeAlign: BorderSide.strokeAlignCenter,
                                                color: Color.fromARGB(255, 179, 179, 179),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),


                                SizedBox(height: h * 0.01),

                                // History cards
                                ...logs.map(
                                    (log) => Padding(
                                      padding: EdgeInsets.only(bottom: h * 0.02, left: w * 0.03),
                                      child: HistoryCardBuilder(
                                        title: log["title"] ?? "",
                                        price: log["price"] ?? "",
                                        subtitle: log["subtitle"] ?? "",
                                        toda: log["toda"] ?? "",
                                        pickup: log["pickup"] ?? "",
                                        locationHistory: log["locationHistory"] ?? "-", // <-- added
                                        onActionTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReportTodaScreen(
                                                toda: log["toda"] ?? "",
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                  ),
                                
                              ],
                            );
                          }),

                          SizedBox(height: h * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating top-right Settings button
                Positioned(
                  top: h * 0.04,
                  right: w * 0.04,
                  child: SettingsButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
