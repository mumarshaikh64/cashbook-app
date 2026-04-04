import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/theme.dart';
import 'business_type_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isSkip;

  const ProfileSetupScreen({super.key, this.isSkip = false});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _businessController = TextEditingController();
  bool _dontOwnBusiness = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _handleNext(context),
            child: const Text('SKIP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FadeInDown(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.person_outline, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(height: 24),
                    const Text('Add Your Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Setting up your profile', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField('Your Full Name', _nameController, 'e.g. M UMAR. SHAIKH'),
              const SizedBox(height: 16),
              _buildTextField('Business Name', _businessController, 'Business/Organisation name', isEnabled: !_dontOwnBusiness),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _dontOwnBusiness,
                    onChanged: (val) => setState(() => _dontOwnBusiness = val!),
                  ),
                  const Text("I don't own a business", style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 60),
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleNext(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('GET STARTED', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isEnabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryColor)),
      ),
    );
  }

  void _handleNext(BuildContext context) {
    // Collect data and go to Business Type Selection
    Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessTypeScreen(
      name: _nameController.text,
      business: _dontOwnBusiness ? "Individual" : _businessController.text,
    )));
  }
}
