// lib/screens/edit_profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _addressController.text = data['address'] ?? '';
          
          // Remove +63 prefix when loading data to show only the mobile number part
          String phone = data['phone'] ?? '';
          if (phone.startsWith('+63')) {
            _phoneController.text = phone.substring(3);
          } else {
            _phoneController.text = phone;
          }
          
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  bool _isValidPhilippinePhoneNumber(String phone) {
    // Remove all spaces and non-digit characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Check if it starts with +63
    if (!cleanPhone.startsWith('+63')) {
      return false;
    }
  
    // Remove +63 to check the remaining digits
    String remainingDigits = cleanPhone.substring(3);
    
    return remainingDigits.length == 10 && 
           remainingDigits.startsWith('9') && 
           RegExp(r'^\d{10}$').hasMatch(remainingDigits);
  }

  String _getPhoneErrorMessage(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!cleanPhone.startsWith('+63')) {
      return 'Phone number must start with +63';
    }
    
    String remainingDigits = cleanPhone.substring(3);
    
    if (remainingDigits.length < 10) {
      return 'Phone number is too short';
    } else if (remainingDigits.length > 10) {
      return 'Phone number is too long';
    } else if (!remainingDigits.startsWith('9')) {
      return 'Mobile number must start with +639';
    }
    
    return 'Invalid Philippine mobile number format';
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate required fields
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required')),
      );
      return;
    }

    // Construct full phone number with +63 prefix
    String fullPhone = '+63$phone';

    // Validate Philippine mobile number format
    if (!_isValidPhilippinePhoneNumber(fullPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getPhoneErrorMessage(fullPhone)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': name,
          'address': address,
          'phone': fullPhone, // Save with +63 prefix
        });

        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          PrimaryButton(
            text: "OK",
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // return to previous screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: h * 0.01),
        CustomTextField(
          hintText: hint,
          controller: controller,
        ),
        SizedBox(height: h * 0.03),
      ],
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller, double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.035,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: h * 0.01),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Prefix container with flag and +63
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border(
                    right: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '🇵🇭',
                      style: TextStyle(fontSize: w * 0.04),
                    ),
                    SizedBox(width: w * 0.01),
                    Text(
                      '+63',
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Text input field
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '9123456789',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: w * 0.04,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  style: TextStyle(
                    fontSize: w * 0.04,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: h * 0.005),
        Text(
          'Enter 10-digit mobile number starting with 9',
          style: TextStyle(
            fontSize: w * 0.03,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: h * 0.03),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    if (!_isDataLoaded) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              // Header
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: h * 0.02),

              // App logo
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

              // Form fields
              _buildTextField('Name', 'Enter your name', _nameController, w, h),
              _buildTextField('Address', 'Enter your address', _addressController, w, h),
              _buildPhoneField('Phone Number', _phoneController, w, h),

              SizedBox(height: h * 0.03),

              // Save Button
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
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
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