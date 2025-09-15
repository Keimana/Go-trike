import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../widgets/card_builder.dart';
import '../widgets/profile_card_builder.dart';
import 'settings_screen.dart';
import 'help.dart'; // ✅ import HelpScreen
import 'edit_profile.dart'; // ✅ import EditProfileScreen

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final cardWidth = w * 0.9;
            final profileCardHeight = h * 0.13;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: h * 0.12, // space reserved for settings button
                    bottom: h * 0.12, // reserve space so scroll avoids logout
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Card
                          ProfileCardBuilder(
                            cardWidth: cardWidth,
                            profileCardHeight: profileCardHeight,
                            name: 'Camille Villar',
                            phone: '+63 912 348 9554',
                          ),

                          SizedBox(height: h * 0.02),

                          // Edit Profile
                          CardBuilder(
                            cardWidth: cardWidth,
                            title: 'Edit Profile',
                            iconPath: 'assets/icons/edit.svg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),

                          // Help
                          CardBuilder(
                            cardWidth: cardWidth,
                            title: 'Help',
                            iconPath: 'assets/icons/help.svg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpScreen(),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: h * 0.03),
                        ],
                      ),
                    ),
                  ),
                ),

                // Logout button fixed at bottom center
                // Logout button fixed above bottom nav bar



                // Top-right Settings button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.04),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
