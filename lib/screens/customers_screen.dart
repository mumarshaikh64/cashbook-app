import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/transaction_provider.dart';
import '../models/party.dart';
import '../utils/formatters.dart';
import '../widgets/custom_modals.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'All'; // All, To Receive, To Pay

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TransactionProvider>().fetchParties());
  }

  Future<void> _sendWhatsAppReminder(
    BuildContext context,
    PartyModel party,
  ) async {
    if (party.phone == null || party.phone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a phone number for this customer first.'),
          backgroundColor: Colors.orange,
        ),
      );
      _showAddOrEditCustomerDialog(context, party: party);
      return;
    }

    final phone = party.phone!.replaceAll(RegExp(r'\D'), '');
    final amount = formatCurrency(party.balance.abs());
    final isReceivable = party.balance > 0;

    String message = '';
    if (isReceivable) {
      message =
          'Hello ${party.name},\n\nThis is a friendly reminder from our store. An amount of $amount is currently outstanding on your Khata account.\n\nKindly clear your pending balance at your earliest convenience. Let us know if you need any clarification.\n\nThank you!';
    } else {
      message =
          'Hello ${party.name},\n\nOur records indicate a credit balance of $amount payable to your account. Please let us know your preferred settlement mode.\n\nThank you!';
    }

    final encodedMsg = Uri.encodeComponent(message);
    final formattedPhone = phone.startsWith('0') ? phone.substring(1) : phone;
    final url = Uri.parse('https://wa.me/+92$formattedPhone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to standard web URL if intent fails
        await launchUrl(
          Uri.parse(
            'https://api.whatsapp.com/send?phone=+92$formattedPhone&text=$encodedMsg',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open WhatsApp. Make sure it is installed.'),
        ),
      );
    }
  }

  void _showAddOrEditCustomerDialog(BuildContext context, {PartyModel? party}) {
    final nameCtrl = TextEditingController(text: party?.name ?? '');
    final phoneCtrl = TextEditingController(text: party?.phone ?? '');
    final addressCtrl = TextEditingController(text: party?.address ?? '');
    final isEdit = party != null;

    CustomModals.showPremiumBottomSheet(
      context: context,
      title: isEdit ? 'Edit Customer Profile' : 'Add New Customer',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit
                  ? 'Update details and contact info below.'
                  : 'Add party/customer details to track outstanding ledgers.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Customer / Party Name*',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'WhatsApp / Phone Number',
                hintText: 'e.g. 923001234567',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF6366F1),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Address / Location (Optional)',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF6366F1),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (isEdit) ...[
                  OutlinedButton(
                    onPressed: () async {
                      final confirm = await CustomModals.showPremiumDialog<bool>(
                        context: context,
                        title: 'Delete Customer Profile?',
                        content: const Text(
                          'Are you sure you want to remove this customer profile? Related transactions will remain unaffected.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('DELETE'),
                          ),
                        ],
                      );
                      if (confirm == true && party.id != null) {
                        await context.read<TransactionProvider>().deleteParty(
                          party.id!,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final updatedParty = PartyModel(
                        id: party?.id,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                      );
                      await context.read<TransactionProvider>().addPartyModel(
                        updatedParty,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'SAVE CHANGES' : 'ADD CUSTOMER',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final allParties = provider.partyModels;

        // Calculate Global Outstanding Metrics
        double totalToReceive = 0;
        double totalToPay = 0;
        for (var p in allParties) {
          if (p.balance > 0) {
            totalToReceive += p.balance;
          } else if (p.balance < 0) {
            totalToPay += p.balance.abs();
          }
        }

        // Apply filters
        List<PartyModel> filteredList = allParties.where((p) {
          final matchesSearch =
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.phone?.contains(_searchQuery) ?? false);

          bool matchesFilter = true;
          if (_filterType == 'To Receive') {
            matchesFilter = p.balance > 0;
          } else if (_filterType == 'To Pay') {
            matchesFilter = p.balance < 0;
          }

          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ── Top Summary Header ─────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'To Receive (+)',
                        totalToReceive,
                        const Color(0xFF10B981),
                        Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'To Pay (-)',
                        totalToPay,
                        const Color(0xFFEF4444),
                        Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search + Filter ────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search customer / phone...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter chips
                    Row(
                      children: ['All', 'To Receive', 'To Pay'].map((type) {
                        final isSelected = _filterType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _filterType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ── Customer List ───────────────────────────────
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final party = filteredList[index];
                          final isReceivable = party.balance > 0;
                          final isPayable = party.balance < 0;
                          final balColor = isReceivable
                              ? const Color(0xFF10B981)
                              : (isPayable
                                    ? const Color(0xFFEF4444)
                                    : Colors.grey);
                          final balLabel = isReceivable
                              ? 'To Receive'
                              : (isPayable ? 'To Pay' : 'Settled');

                          return FadeInUp(
                            duration: const Duration(milliseconds: 250),
                            delay: Duration(milliseconds: index * 40),
                            child: GestureDetector(
                              onTap: () => _showAddOrEditCustomerDialog(
                                context,
                                party: party,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                    topLeft: Radius.circular(3.5),
                                    bottomLeft: Radius.circular(3.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Colored left accent bar
                                    Container(
                                      width: 4,
                                      height: 75,
                                      decoration: BoxDecoration(
                                        color: balColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: balColor.withOpacity(
                                        0.12,
                                      ),
                                      child: Text(
                                        party.name.isNotEmpty
                                            ? party.name[0].toUpperCase()
                                            : 'C',
                                        style: TextStyle(
                                          color: balColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Name + info
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              party.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            if (party.phone != null &&
                                                party.phone!.isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone_outlined,
                                                    size: 11,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    party.phone!,
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text(
                                                '+ Add phone number',
                                                style: TextStyle(
                                                  color: Colors.amber[600],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Balance + WhatsApp
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            formatCurrency(party.balance.abs()),
                                            style: TextStyle(
                                              color: balColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: balColor.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  balLabel,
                                                  style: TextStyle(
                                                    color: balColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (party.balance != 0) ...[
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _sendWhatsAppReminder(
                                                        context,
                                                        party,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF25D366,
                                                      ).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.chat_bubble,
                                                      color: Color(0xFF25D366),
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrEditCustomerDialog(context),
            backgroundColor: const Color(0xFF6366F1),
            elevation: 4,
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.white,
            ),
            label: const Text(
              'ADD CUSTOMER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterType != 'All'
                ? 'No customers match your criteria'
                : 'No customer records yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your customers to record outstanding credit/debit',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
