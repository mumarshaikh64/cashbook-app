import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      //   title: const Text(
      //     'Help & Support',
      //     style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
      //   ),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Card
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cashbook by Softgrid',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Section
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: const Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ..._buildFaqItems(),

            const SizedBox(height: 24),

            // How to Use Section
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'How to Use',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildHowToCard(
              '1',
              'Create a Book',
              'Tap the "+" button on the home screen to create a new cashbook for your business or personal use.',
              Icons.add_circle_outline,
            ),
            _buildHowToCard(
              '2',
              'Add Entries',
              'Open any book and tap "CASH IN" or "CASH OUT" to record your daily transactions.',
              Icons.receipt_long_outlined,
            ),
            _buildHowToCard(
              '3',
              'Track Balance',
              'View your total cash in, cash out, and net balance at the top of each book.',
              Icons.account_balance_wallet_outlined,
            ),
            _buildHowToCard(
              '4',
              'Generate Reports',
              'Tap the report icon to generate PDF or Excel reports. You can filter by day, contact, or category.',
              Icons.picture_as_pdf_outlined,
            ),
            _buildHowToCard(
              '5',
              'Edit & Delete',
              'Tap any entry to view details. Use the edit or delete icons in the top bar to modify entries.',
              Icons.edit_outlined,
            ),

            const SizedBox(height: 24),

            // Contact Support
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'Contact Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              Icons.email_outlined,
              'Email Us',
              'info@softgrid.solutions',
              const Color(0xFF6366F1),
              () => launchUrl(Uri.parse('mailto:info@softgrid.solutions')),
            ),
            _buildContactCard(
              Icons.language,
              'Visit Website',
              'softgrid.solutions',
              const Color(0xFF10B981),
              () => launchUrl(Uri.parse('https://softgrid.solutions'), mode: LaunchMode.externalApplication),
            ),
            _buildContactCard(
              Icons.phone_outlined,
              'Call Us',
              '+92 3202287330',
              const Color(0xFFF59E0B),
              () => launchUrl(Uri.parse('tel:+923202287330')),
            ),

            const SizedBox(height: 24),

            // Tips Section
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFF59E0B),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pro Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use the party name field to tag contacts. This helps generate accurate contact-wise reports for your business.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: const [
                  Text(
                    'Made with ❤️ by Softgrid Solutions',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '© 2026 All rights reserved',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFaqItems() {
    final faqs = [
      {
        'q': 'How do I create a new cashbook?',
        'a':
            'Tap the "+" floating button on the home screen, enter a name for your book, and tap create. You can create multiple books for different businesses or purposes.',
      },
      {
        'q': 'Can I edit or delete an entry?',
        'a':
            'Yes! Tap on any transaction to open the detail view. Use the edit (pencil) icon to modify it or the delete (trash) icon to remove it permanently.',
      },
      {
        'q': 'How do I generate reports?',
        'a':
            'Open a book and tap the report icon (PDF) in the top bar, or use the "Generate Report" button in the summary card. Choose your report type and format (PDF or Excel).',
      },
      {
        'q': 'Can I share reports?',
        'a':
            'Absolutely! After generating a report, you\'ll see a success screen with "View Report" and "Send/Share" buttons. Share via WhatsApp, Email, or any other app.',
      },
      {
        'q': 'Is my data safe?',
        'a':
            'All your data is stored locally on your device using a secure SQLite database. We recommend generating regular backup reports.',
      },
      {
        'q': 'Can I filter transactions by date?',
        'a':
            'Yes! Use the calendar icon in the filter bar inside each book to pick a date range and filter entries.',
      },
    ];

    return faqs.asMap().entries.map((entry) {
      final index = entry.key;
      final faq = entry.value;
      return FadeInUp(
        delay: Duration(milliseconds: 100 + index * 50),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.help_outline,
                  color: Color(0xFF6366F1),
                  size: 18,
                ),
              ),
            ),
            title: Text(
              faq['q']!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            children: [
              Text(
                faq['a']!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildHowToCard(
    String step,
    String title,
    String desc,
    IconData icon,
  ) {
    return FadeInUp(
      delay: Duration(milliseconds: 150 + int.parse(step) * 50),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: const Color(0xFF6366F1), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    IconData icon,
    String title,
    String value,
    Color color,
    VoidCallback onTap,
  ) {
    return FadeInUp(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
