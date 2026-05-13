import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
        child: FadeInUp(
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
                'Last Updated: May 2026',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              _buildSection(
                title: '1. Introduction',
                content:
                    'At Softgrid Solutions, safeguarding your privacy is our top priority. This Privacy Policy details how the Naya Khata application handles, secures, and maintains your data when you utilize our business ledger services.',
              ),

              _buildSection(
                title: '2. Information We Collect',
                content:
                    '• Authentication Identity: When you sign up via Email or Google Auth, we receive basic identifying details (Email address, profile display name, and avatar picture) provided by the OAuth provider.\n• Profile Metadata: Details entered voluntarily such as your Business Name, Tagline, Category, and localized details.\n• Transaction Ledger: The individual transaction records, timestamps, parties, and numerical figures you enter into your ledgers.',
              ),

              _buildSection(
                title: '3. Data Storage & Cloud Integration',
                content:
                    'Unlike traditional SaaS web products that hoard continuous business logs centrally, Naya Khata adopts a user-centric data model. Your SQLite transaction database file resides directly inside your device sandbox.\n\nWhen Google Drive Backup is enabled, the app directly synchronizes encrypted backup archives solely into your private Google Drive directory. We do not inspect, mine, or transmit your individual ledger sheets to third-party ad networks.',
              ),

              _buildSection(
                title: '4. Third-Party Services',
                content:
                    'Naya Khata integrates trusted vendor frameworks to maintain infrastructure reliability:\n• Firebase Authentication: Manages secure credentials and account lifecycles.\n• Google Drive API: Handles secure user-delegated file backup operations.',
              ),

              _buildSection(
                title: '5. Permissions Requested',
                content:
                    '• Internet Access: Essential for verifying Firebase authorization tokens and communicating with your linked Google Drive space.\n• External Storage / Photos: Required strictly when you decide to pick business profile logo pictures or generate exportable PDF transaction reports.',
              ),

              _buildSection(
                title: '6. Your Rights & Data Deletion',
                content:
                    'Since ledger content is stored locally, uninstalling the app clears your active runtime ledger state. To remove synced archives, you can directly delete the backup files residing inside your Google Drive. You may also execute complete profile logouts directly inside our Settings menu.',
              ),

              _buildSection(
                title: '7. Policy Changes',
                content:
                    'We may periodically update this policy to reflect platform API adjustments or enhanced security specifications. Ongoing access denotes compliance with the updated terms.',
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

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
