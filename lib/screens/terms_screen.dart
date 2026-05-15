import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isLoading = true;
  String _termsText = '';

  // Original fallback stream guaranteeing offline reliability
  final String _fallbackTermsText = '''1. Acceptance of Terms
By accessing, downloading, or using the Naya Khata mobile application ("App"), you agree to be bound by these Terms & Conditions. If you do not agree to these terms, please do not use the application.

2. Purpose of the Application
Naya Khata is a digital ledger and cashbook tool designed to help individuals and businesses manage their daily debit/credit records, customer transactions, and financial summaries. The App acts solely as a self-managed recording tool.

3. Data Storage & Ownership
Your ledger records, customer details, and transactions are primarily stored locally on your device. When you enable Google Drive Backup, an encrypted snapshot of your database is synchronized to your personal Google Drive cloud storage. Naya Khata does not host your business ledgers on public servers and assumes no ownership over your transaction entries.

4. Accuracy of Records
You are solely responsible for the accuracy, legality, and correctness of all transaction entries and customer balances managed inside the App. Naya Khata is not responsible for any direct or indirect financial disputes, loss of profits, or accounting errors arising between you and your customers.

5. Account Security
You are responsible for safeguarding your login credentials (Email/Password or Google Account access) used to authenticate inside Naya Khata. We recommend keeping your device protected with appropriate authentication (PIN, fingerprint, or face unlock).

6. Modifications to Service
Softgrid Solutions reserves the right to modify, update, suspend, or discontinue any feature of the App at any time. We will continually endeavor to provide notifications regarding significant feature updates.

7. Contact Us
For any compliance inquiries, feature suggestions, or dispute reports, please contact our support desk via the Help section inside the App.''';

  @override
  void initState() {
    super.initState();
    _fetchTerms();
  }

  Future<void> _fetchTerms() async {
    try {
      // Connect to target administrative host API resolution address
      const String targetUrl = 'http://192.168.100.116:3002/api/legal';
      
      final response = await http.get(Uri.parse(targetUrl)).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['terms_conditions'] != null) {
          setState(() {
            _termsText = data['terms_conditions'];
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
        _termsText = _fallbackTermsText;
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
          'Terms & Conditions',
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
                  color: Color(0xFF6366F1),
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
                      _termsText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                      ),
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
}
