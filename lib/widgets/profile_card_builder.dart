import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ added

/// Profile card builder (name + phone + avatar)
class ProfileCardBuilder extends StatelessWidget {
  final double cardWidth;
  final double profileCardHeight;
  final String? name; // ✅ made optional
  final String phone;

  const ProfileCardBuilder({
    super.key,
    required this.cardWidth,
    required this.profileCardHeight,
    this.name, // ✅ optional now
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // ✅ Always fetch latest Firebase user displayName if name is not provided
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String displayName = name ?? currentUser?.displayName ?? 'User';

    return Container(
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
                  displayName, // ✅ synced with FirebaseAuth
                  style: TextStyle(
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: h * 0.004),
                Text(
                  phone,
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
    );
  }
}
