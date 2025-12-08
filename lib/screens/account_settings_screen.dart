import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../widgets/card_builder.dart';
import '../widgets/profile_card_builder.dart';
import 'settings_screen.dart';
import 'help.dart';
import 'edit_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      print('Loading user data for UID: $uid'); // Debug log

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (doc.exists) {
        print('User data found: ${doc.data()}'); // Debug log
        return doc.data();
      } else {
        print('No user document found for UID: $uid'); // Debug log
        // Return default data if document doesn't exist
        final user = FirebaseAuth.instance.currentUser;
        return {
          'name': user?.displayName ?? 'Unknown User',
          'phone': 'No phone number',
          'email': user?.email ?? 'No email',
        };
      }
    } catch (e) {
      print('Error loading user data: $e'); // Debug log
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final userData = snapshot.data;
          if (userData == null) {
            return const Center(child: Text("No user data found"));
          }

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final safeTop = MediaQuery.of(context).padding.top;
                final cardWidth = w * 0.9;
                final profileCardHeight = h * 0.13;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: h * 0.12,
                        bottom: h * 0.12,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile Card with dynamic data
                              ProfileCardBuilder(
                                cardWidth: cardWidth,
                                profileCardHeight: profileCardHeight,
                                name: userData['name'] ?? 'Unknown User',
                                phone: userData['phone'] ?? 'No phone number',
                              ),
                              
                              SizedBox(height: h * 0.02),
                              
                              // Edit Profile
                              CardBuilder(
                                cardWidth: cardWidth,
                                title: 'Edit Profile',
                                iconPath: 'assets/icons/edit.svg',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                ),
                              ),
                              
                              // Help
                              CardBuilder(
                                cardWidth: cardWidth,
                                title: 'Help',
                                iconPath: 'assets/icons/help.svg',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HelpScreen(),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: h * 0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Top-right Settings button
                    Positioned(
                      top: safeTop + h * 0.02,
                      right: w * 0.04,
                      child: SettingsButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}