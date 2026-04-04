import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/theme.dart';
import 'cashbooks_screen.dart';

class BusinessTypeScreen extends StatefulWidget {
  final String? name;
  final String? business;

  const BusinessTypeScreen({super.key, this.name, this.business});

  @override
  _BusinessTypeScreenState createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  String? _selectedType;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _types = [
    {'label': 'Retailer', 'icon': Icons.storefront_outlined},
    {'label': 'Distributor', 'icon': Icons.local_shipping_outlined},
    {'label': 'Manufacturer', 'icon': Icons.factory_outlined},
    {'label': 'Service Provider', 'icon': Icons.build_outlined},
    {'label': 'Trader', 'icon': Icons.business_center_outlined},
    {'label': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () => _handleDone(context),
            child: const Text('SKIP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text('Select Business Type', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This will help us personalise your app experience', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final isSelected = _selectedType == type['label'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = type['label']),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[200]!, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(type['icon'], color: isSelected ? Colors.blue : Colors.blueGrey),
                            const SizedBox(width: 16),
                            Text(type['label'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const Spacer(),
                            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('Business Setup: Step 2/2', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedType == null ? null : () => _handleDone(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _selectedType == null ? Colors.grey[300] : AppTheme.primaryColor,
                      ),
                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business_outlined, color: Colors.blue),
                  const SizedBox(width: 16),
                  const Text('Setting up your CashBook account', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }

  void _handleDone(BuildContext context) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Save to Provider
    await context.read<AppProvider>().completeOnboarding(
      name: widget.name,
      business: widget.business,
      type: _selectedType,
    );

    // Create First Default Book automatically
    if (mounted) {
      await context.read<TransactionProvider>().createBook('Business Book');
    }

    if (!mounted) return;

    // Final navigation to Cashbooks Screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => CashbooksScreen()),
      (route) => false,
    );
  }
}
