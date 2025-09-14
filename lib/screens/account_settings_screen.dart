import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/settings_button.dart';
import '../widgets/logout_button.dart';
import 'settings_screen.dart';

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
            final cardHeight = h * 0.08; // logout button height
            final profileCardHeight = h * 0.13;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 600), // ✅ Limit for wide screens
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: h * 0.120), // space for Settings button

                          // Profile Card
                          Container(
                            width: cardWidth,
                            padding: EdgeInsets.all(w * 0.04),
                            margin: EdgeInsets.symmetric(vertical: h * 0.01),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Profile picture
                                Container(
                                  width: profileCardHeight * 0.6,
                                  height: profileCardHeight * 0.6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(profileCardHeight * 0.15),
                                    child: SvgPicture.asset(
                                      'assets/icons/person.svg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(width: w * 0.05),

                                // Profile info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Camille Villar',
                                        style: TextStyle(
                                          fontSize: w * 0.045, // scale with screen
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: h * 0.004),
                                      Text(
                                        '+63 912 348 9554',
                                        style: TextStyle(
                                          fontSize: w * 0.035,
                                          color: Colors.grey[800],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit Profile & Help
                          _buildCard(context, cardWidth, 'Edit Profile',
                              iconPath: 'assets/icons/edit.svg'),
                          _buildCard(context, cardWidth, 'Help',
                              iconPath: 'assets/icons/help.svg'),

                          SizedBox(height: h * 0.02),

                          // Logout button
                          LogoutButton(width: cardWidth, height: cardHeight),

                          SizedBox(height: h * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top-right Settings button
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

  /// Card builder for Edit Profile & Help
  Widget _buildCard(BuildContext context, double cardWidth, String title,
      {String? iconPath}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (title == 'Edit Profile') {
              Navigator.pushNamed(context, '/edit-profile');
            } else if (title == 'Help') {
              Navigator.pushNamed(context, '/help');
            }
          },
          child: Container(
            width: cardWidth,
            height: cardWidth * 0.16,
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.04),
            child: Row(
              children: [
                if (iconPath != null) ...[
                  SvgPicture.asset(
                    iconPath,
                    width: cardWidth * 0.07,
                    height: cardWidth * 0.07,
                  ),
                  SizedBox(width: cardWidth * 0.03),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: cardWidth * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: cardWidth * 0.045),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
