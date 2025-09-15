// lib/screens/help.dart
import 'package:flutter/material.dart';
import '../widgets/card_builder.dart';
import 'document_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Help',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(
                      color: const Color(0xFF0097B2),
                      fontSize: w * 0.08,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' ',
                    style: TextStyle(
                      color: const Color(0xFF34C759),
                      fontSize: w * 0.08,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: 'Trike',
                    style: TextStyle(
                      color: const Color(0xFFFF9500),
                      fontSize: w * 0.08,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Help',
              style: TextStyle(
                fontSize: w * 0.07,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Rules & Guidelines
            CardBuilder(
              cardWidth: w * 0.9,
              title: 'Rules & Guidelines',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentScreen(
                      title: "Rules & Guidelines",
                      content: """
1. Rules & Guidelines

Eligibility
- Users must be at least 18 years old to register and book rides.
- Minors may use the service with parental or guardian consent and supervision.

User Conduct
- Passengers must provide accurate booking details (pickup and drop-off).
- Drivers must follow local Barangay TODA rules, traffic laws, and agreed booking terms.
- Both parties must observe respectful and safe behavior during rides.

Fares & Payments
- Payments are cash-based unless digital payment is officially introduced.
- Passengers must pay the agreed fare; drivers may not overcharge beyond LTFRB standards.

Safety & Security
- Drivers must display their Body Number as sent by the system for transparency.
- Users are encouraged to report misconduct through the feedback system.
- Emergency contact numbers will be available for urgent incidents.

Termination of Access
Accounts may be suspended or terminated for:
- Fraudulent bookings
- Harassment, threats, or unsafe behavior
- Misuse of the application

Prohibited Uses
Users agree not to:
- Engage in fraudulent, misleading, or malicious activities
- Attempt to hack, reverse-engineer, or interfere with the app’s operation
- Spam or abuse the booking system
""",
                    ),
                  ),
                );
              },
            ),

            // Terms of Service
            CardBuilder(
              cardWidth: w * 0.9,
              title: 'Terms of Service',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentScreen(
                      title: "Terms of Service",
                      content: """
2. Terms of Service (ToS)

By using GoTrike, you agree to the following:

Service Scope
- GoTrike is available only within Barangay 301, Telebastagan, San Fernando, Pampanga.
- The app is intended for real-time tricycle booking, not long-distance travel or delivery.

Booking Process
- Requests are sent to the nearest terminal; if unanswered, the request moves to the next nearest terminal.
- Accepting requests is managed by the Terminal device.

Responsibilities
- Passengers: Ensure correct details and timely payment.
- Drivers: Provide safe rides and respect agreed fares.
- Admin/TODA: Manage user records, ride history, and enforce compliance with rules.

Limitations of Liability
- GoTrike serves as a platform and does not guarantee immediate ride availability.
- The Barangay TODA and GoTrike developers are not liable for accidents, loss of property, or disputes, though reports will be recorded and investigated.

Account Security
- Users are responsible for safeguarding login credentials.
- Any activity under a user account is treated as authorized unless reported.

Service Availability
- GoTrike may be temporarily unavailable due to maintenance, connectivity issues, or events beyond control.
- The app is not liable for delays, cancellations, or interruptions caused by such events.

Changes to Terms & Service
- GoTrike may update these Terms, Rules, or the Privacy Policy at any time.
- Continued use indicates acceptance of the updated terms.

Governing Law & Dispute Resolution
- These Terms are governed by the laws of the Republic of the Philippines.
- Disputes will be settled under the jurisdiction of the proper courts in San Fernando, Pampanga, with TODA mediation encouraged first.

Third-Party Services
- The app may integrate services such as Google Maps and Firebase.
- Their separate terms and privacy policies govern any data they collect.
""",
                    ),
                  ),
                );
              },
            ),

            // Privacy Policy
            CardBuilder(
              cardWidth: w * 0.9,
              title: 'Privacy Policy',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentScreen(
                      title: "Privacy Policy",
                      content: """
3. Privacy Policy

Information Collected
- User Profile: Name, address, contact number, and age (for safety).
- Ride Data: Pickup and drop-off points, ride history, driver body numbers.
- Feedback: Complaints, ratings, and reviews of rides.

Use of Information
- To process bookings and connect passengers with drivers.
- To monitor driver activity and ride history for safety.
- To improve the system through analytics and user feedback.

Data Protection
- All personal data is stored securely using Firebase/Firestore security rules.
- Access is limited to authorized TODA admins.
- Sensitive data is protected under the Data Privacy Act of 2012 (RA 10173).

Data Retention
- Ride history and personal data are retained only as long as needed for legal, operational, and safety purposes.
- Data will be securely deleted once it is no longer required.

Data Sharing
- User data will not be sold or shared with third parties.
- Data may be shared with local authorities if required by law or in emergencies.

Children’s Privacy
- GoTrike does not knowingly collect personal data from minors without parental consent.
- Parents or guardians may request deletion of a minor’s data at any time.

User Rights
- Users can request to view, update, or delete their data.
- Consent is required before any personal data is collected.
""",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
