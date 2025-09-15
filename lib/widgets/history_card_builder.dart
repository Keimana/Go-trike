import 'package:flutter/material.dart';

class HistoryCardBuilder extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String toda;
  final String pickup; // pickup location
  final String locationHistory; // <-- new field
  final VoidCallback onActionTap; // Added for button tap

  const HistoryCardBuilder({
    super.key,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.toda,
    required this.pickup,
    required this.locationHistory, // <-- new
    required this.onActionTap, // Added
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.03),
        child: Container(
          width: w * 0.9,
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: w * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: w * 0.01),

              // Price + floating Report button in Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: w * 0.035,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(), // push button to the right
                  ElevatedButton(
                    onPressed: onActionTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5744),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
                        vertical: w * 0.012,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Report",
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: w * 0.01),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: w * 0.005),

              // Pickup location
              Text(
                "Pickup: $pickup",
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: w * 0.005),

              // Location history / route
              Text(
                "Route: $locationHistory",
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: w * 0.005),

              // Toda #
              Text(
                toda,
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
