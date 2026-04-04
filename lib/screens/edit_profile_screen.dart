import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _businessCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  String? _selectedType;
  String? _logoPath;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _types = [
    {'label': 'Retailer', 'icon': Icons.storefront_outlined},
    {'label': 'Distributor', 'icon': Icons.local_shipping_outlined},
    {'label': 'Manufacturer', 'icon': Icons.factory_outlined},
    {'label': 'Service Provider', 'icon': Icons.build_outlined},
    {'label': 'Trader', 'icon': Icons.business_center_outlined},
    {'label': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _nameCtrl = TextEditingController(text: p.userName ?? '');
    _businessCtrl = TextEditingController(text: p.businessName ?? '');
    _addressCtrl = TextEditingController(text: p.address ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _selectedType = p.businessType;
    _logoPath = p.logoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await context.read<AppProvider>().updateProfile(
      name: _nameCtrl.text.trim(),
      businessName: _businessCtrl.text.trim(),
      businessType: _selectedType,
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      logoPath: _logoPath,
    );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Profile updated successfully!')]),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('SAVE', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // ── Logo Section ─────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEEF2FF),
                            border: Border.all(color: const Color(0xFF6366F1), width: 2),
                            image: _logoPath != null
                                ? DecorationImage(image: FileImage(File(_logoPath!)), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _logoPath == null
                              ? Center(
                                  child: Text(
                                    _businessCtrl.text.isNotEmpty ? _businessCtrl.text[0].toUpperCase() : 'B',
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to change logo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Personal Info ─────────────────────────
            _buildSection(
              'Personal Info',
              [
                _buildField('Your Full Name', _nameCtrl, Icons.person_outline, required: true),
                _buildField('Email Address', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
              ],
            ),
            const SizedBox(height: 12),

            // ── Company Info ──────────────────────────
            _buildSection(
              'Company Info',
              [
                _buildField('Company / Business Name', _businessCtrl, Icons.business_outlined, required: true),
                _buildField('Address', _addressCtrl, Icons.location_on_outlined, maxLines: 2),
              ],
            ),
            const SizedBox(height: 12),

            // ── Organization Type ─────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORGANIZATION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: _types.map((type) {
                      final isSelected = _selectedType == type['label'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = type['label']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 14), child: f)).toList(),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        filled: true,
        fillColor: const Color(0xFFFAFAFF),
        labelStyle: const TextStyle(color: Colors.grey),
        floatingLabelStyle: const TextStyle(color: Color(0xFF6366F1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: required ? (val) => (val == null || val.trim().isEmpty) ? '$label is required' : null : null,
    );
  }
}
