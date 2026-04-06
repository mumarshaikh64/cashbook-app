import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../services/report_service.dart';
import 'report_success_screen.dart';

class ReportScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String bookName;

  const ReportScreen({required this.transactions, required this.bookName, super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedReportType = 'All Entries Report';
  
  // Default Settings
  Map<String, bool> _reportSettings = {
    'Balance': true,
    'Remark': true,
    'Contact Name': true,
    'Member': true,
    'Category': true,
    'Payment Mode': true,
    'Time': false,
    'Date': true,
    'Cash In': true,
    'Cash Out': true,
    'Your name and mobile number': true,
    'Applied Filters': true,
  };

  final List<Map<String, String>> _reportTypes = [
    {
      'title': 'All Entries Report',
      'subtitle': 'List of all entries and details',
    },
    {
      'title': 'Day-wise summary',
      'subtitle': 'Day-wise total in, out & balance',
    },
    {
      'title': 'Contact-wise summary',
      'subtitle': 'Contact-wise total in, out & balance',
    },
    {
      'title': 'Category-wise summary',
      'subtitle': 'Income & expenses of all categories',
    },
    {
      'title': 'Payment Modes summary',
      'subtitle': 'Income & expenses by all payment modes',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Generate Report',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF6366F1)),
                onPressed: () async {
                  final newSettings = await Navigator.push<Map<String, bool>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfSettingsScreen(
                        initialSettings: _reportSettings,
                        appProvider: appProvider,
                      ),
                    ),
                  );
                  if (newSettings != null) {
                    setState(() => _reportSettings = newSettings);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildShareBanner(),
              _buildReportSummary(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Select Report Type',
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _reportTypes.length,
                  itemBuilder: (context, index) {
                    final type = _reportTypes[index];
                    final isSelected = _selectedReportType == type['title'];
                    
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: RadioListTile<String>(
                          value: type['title']!,
                          groupValue: _selectedReportType,
                          onChanged: (val) => setState(() => _selectedReportType = val!),
                          activeColor: const Color(0xFF6366F1),
                          title: Text(
                            type['title']!,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF4338CA) : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            type['subtitle']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildActionButtons(appProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.group, color: Color(0xFF6366F1), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Share books with multiple members',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Tap here to know more',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report will be generated for',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Duration', 'All Time'),
              _buildSummaryItem('Entry Type', 'All'),
              _buildSummaryItem('Payment Mode', 'All'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem('Search Term', 'None'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final path = await ReportService.generateExcel(
                transactions: widget.transactions,
                bookName: widget.bookName,
                settings: _reportSettings,
                reportType: _selectedReportType,
                businessName: appProvider.businessName,
              );
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportSuccessScreen(
                      filePath: path,
                      bookName: widget.bookName,
                      reportType: _selectedReportType,
                    ),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Color(0xFF6366F1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.table_chart_outlined, size: 20),
            label: const Text('GENERATE EXCEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final path = await ReportService.generatePdf(
                transactions: widget.transactions,
                bookName: widget.bookName,
                settings: _reportSettings,
                reportType: _selectedReportType,
                businessName: appProvider.businessName,
                logoPath: appProvider.logoPath,
              );
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportSuccessScreen(
                      filePath: path,
                      bookName: widget.bookName,
                      reportType: _selectedReportType,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('GENERATE PDF', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}

class PdfSettingsScreen extends StatefulWidget {
  final Map<String, bool> initialSettings;
  final AppProvider appProvider;
  const PdfSettingsScreen({required this.initialSettings, required this.appProvider, super.key});

  @override
  _PdfSettingsScreenState createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  late Map<String, bool> _settings;
  final List<String> _compulsory = ['Date', 'Cash In', 'Cash Out'];

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.initialSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PDF Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessIdentity(widget.appProvider),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Select columns you wish to include in report :',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ),
            ..._settings.keys.take(10).map((key) => _buildCheckItem(key)),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Other Options',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ..._settings.keys.skip(10).map((key) => _buildCheckItem(key)),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildBusinessIdentity(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text('Tap below to update your logo/name in settings', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  child: appProvider.logoPath != null && File(appProvider.logoPath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(appProvider.logoPath!), fit: BoxFit.cover),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, color: Color(0xFF6366F1)),
                      ),
                ),
                Text(appProvider.businessName ?? 'MY BUSINESS', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title) {
    final bool isCompulsory = _compulsory.contains(title);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCompulsory ? Colors.grey[100] : (_settings[title]! ? const Color(0xFFEEF2FF).withOpacity(0.5) : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: isCompulsory ? Colors.grey : Colors.black87)),
            if (isCompulsory) ...[
              const Spacer(),
              const Text('Compulsory', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]
          ],
        ),
        value: _settings[title],
        onChanged: isCompulsory ? null : (val) => setState(() => _settings[title] = val!),
        activeColor: const Color(0xFF6366F1),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _settings),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
