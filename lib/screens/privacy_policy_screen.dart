import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isLoading = true;
  String _policyText = '';

  // Original fallback stream guaranteeing offline reliability
  final String _fallbackPolicyText = '''1. Introduction
At Softgrid Solutions, safeguarding your privacy is our top priority. This Privacy Policy details how the Naya Khata application handles, secures, and maintains your data when you utilize our business ledger services.

2. Information We Collect
• Authentication Identity: When you sign up via Email or Google Auth, we receive basic identifying details (Email address, profile display name, and avatar picture) provided by the OAuth provider.
• Profile Metadata: Details entered voluntarily such as your Business Name, Tagline, Category, and localized details.
• Transaction Ledger: The individual transaction records, timestamps, parties, and numerical figures you enter into your ledgers.

3. Data Storage & Cloud Integration
Unlike traditional SaaS web products that hoard continuous business logs centrally, Naya Khata adopts a user-centric data model. Your SQLite transaction database file resides directly inside your device sandbox.

When Google Drive Backup is enabled, the app directly synchronizes encrypted backup archives solely into your private Google Drive directory. We do not inspect, mine, or transmit your individual ledger sheets to third-party ad networks.

4. Third-Party Services
Naya Khata integrates trusted vendor frameworks to maintain infrastructure reliability:
• Firebase Authentication: Manages secure credentials and account lifecycles.
• Google Drive API: Handles secure user-delegated file backup operations.

5. Permissions Requested
• Internet Access: Essential for verifying Firebase authorization tokens and communicating with your linked Google Drive space.
• External Storage / Photos: Required strictly when you decide to pick business profile logo pictures or generate exportable PDF transaction reports.

6. Your Rights & Data Deletion
Since ledger content is stored locally, uninstalling the app clears your active runtime ledger state. To remove synced archives, you can directly delete the backup files residing inside your Google Drive. You may also execute complete profile logouts directly inside our Settings menu.

7. Policy Changes
We may periodically update this policy to reflect platform API adjustments or enhanced security specifications. Ongoing access denotes compliance with the updated terms.''';

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  Future<void> _fetchPrivacyPolicy() async {
    try {
      // Connect to target administrative host API resolution address
      // Uses 10.0.2.2 for Android emulator fallback resolution or direct loopback
      const String targetUrl = 'http://192.168.100.116:3002/api/legal';
      
      final response = await http.get(Uri.parse(targetUrl)).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['privacy_policy'] != null) {
          setState(() {
            _policyText = data['privacy_policy'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Handshake interrupted, defer cleanly to bundled offline template
    }

    if (mounted) {
      setState(() {
        _policyText = _fallbackPolicyText;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                ),
              )
            : FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header Icon & Title
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Color(0xFF10B981),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Naya Khata Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live Synchronized Stream',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Render Dynamic Buffer string blocks seamlessly
                    Text(
                      _policyText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'Naya Khata © Softgrid Solutions. Protected & Secure.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
