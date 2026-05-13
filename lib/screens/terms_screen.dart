import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

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
          'Terms & Conditions',
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
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Color(0xFF6366F1),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Naya Khata Terms of Service',
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
                title: '1. Acceptance of Terms',
                content:
                    'By accessing, downloading, or using the Naya Khata mobile application ("App"), you agree to be bound by these Terms & Conditions. If you do not agree to these terms, please do not use the application.',
              ),

              _buildSection(
                title: '2. Purpose of the Application',
                content:
                    'Naya Khata is a digital ledger and cashbook tool designed to help individuals and businesses manage their daily debit/credit records, customer transactions, and financial summaries. The App acts solely as a self-managed recording tool.',
              ),

              _buildSection(
                title: '3. Data Storage & Ownership',
                content:
                    'Your ledger records, customer details, and transactions are primarily stored locally on your device. When you enable Google Drive Backup, an encrypted snapshot of your database is synchronized to your personal Google Drive cloud storage. Naya Khata does not host your business ledgers on public servers and assumes no ownership over your transaction entries.',
              ),

              _buildSection(
                title: '4. Accuracy of Records',
                content:
                    'You are solely responsible for the accuracy, legality, and correctness of all transaction entries and customer balances managed inside the App. Naya Khata is not responsible for any direct or indirect financial disputes, loss of profits, or accounting errors arising between you and your customers.',
              ),

              _buildSection(
                title: '5. Account Security',
                content:
                    'You are responsible for safeguarding your login credentials (Email/Password or Google Account access) used to authenticate inside Naya Khata. We recommend keeping your device protected with appropriate authentication (PIN, fingerprint, or face unlock).',
              ),

              _buildSection(
                title: '6. Modifications to Service',
                content:
                    'Softgrid Solutions reserves the right to modify, update, suspend, or discontinue any feature of the App at any time. We will continually endeavor to provide notifications regarding significant feature updates.',
              ),

              _buildSection(
                title: '7. Contact Us',
                content:
                    'For any compliance inquiries, feature suggestions, or dispute reports, please contact our support desk via the Help section inside the App.',
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Naya Khata © Softgrid Solutions. All Rights Reserved.',
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
              color: Color(0xFF6366F1),
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
