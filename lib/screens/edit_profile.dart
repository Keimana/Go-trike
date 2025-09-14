// lib/screens/edit_profile.dart
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart'; // <-- add this import

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    // Just front-end (no backend)
    debugPrint("Saved profile: $name | $address | $phone");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Profile Saved",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: const Text(
            "Your profile changes have been saved successfully!",
            style: TextStyle(color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.only(
            bottom: 16,
            right: 16,
            left: 16,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // Use your PrimaryButton widget here
            PrimaryButton(
              text: "OK",
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, {
                  "name": name,
                  "address": address,
                  "phone": phone,
                }); // return values if needed
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App logo style text
              Text.rich(
                TextSpan(
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
                    const TextSpan(text: ' '),
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

              SizedBox(height: h * 0.04),

              // Name
              Text('Name',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  )),
              SizedBox(height: h * 0.01),
              CustomTextField(
                hintText: 'Enter your name',
                controller: _nameController,
              ),
              SizedBox(height: h * 0.03),

              // Address
              Text('Address',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  )),
              SizedBox(height: h * 0.01),
              CustomTextField(
                hintText: 'Enter your address',
                controller: _addressController,
              ),
              SizedBox(height: h * 0.03),

              // Phone
              Text('Phone Number',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  )),
              SizedBox(height: h * 0.01),
              CustomTextField(
                hintText: 'Enter your phone number',
                controller: _phoneController,
              ),

              SizedBox(height: h * 0.06),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _saveProfile,
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.045,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
