import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:animate_do/animate_do.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import '../utils/formatters.dart';
import '../models/transaction.dart';
import '../models/book.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'report_screen.dart';
import '../services/google_drive_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  bool _isSearching = false;
  
  String? _lastBackup;
  String? _googlePhoto;
  bool _isCloudConnected = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TransactionProvider>().fetchTransactions();
      _loadCloudStatus();
    });
  }

  Future<void> _loadCloudStatus() async {
    final service = GoogleDriveService();
    final status = await service.isSignedIn();
    final info = await service.getAccountInfo();
    if (mounted) {
      setState(() {
        _isCloudConnected = status;
        _lastBackup = info['lastBackup'];
        _googlePhoto = info['photo'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final book = provider.currentBook!;
        final isLoading = provider.isLoading;

        List<TransactionModel> filteredList = provider.transactions.where((t) {
          final matchesSearch = _searchQuery.isEmpty ||
              (t.partyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              t.amount.toString().contains(_searchQuery);

          bool matchesDate = true;
          if (_selectedDateRange != null) {
            final entryDate = DateTime(t.date.year, t.date.month, t.date.day);
            final startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            final endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
            matchesDate = (entryDate.isAtSameMomentAs(startDate) || entryDate.isAfter(startDate)) &&
                (entryDate.isAtSameMomentAs(endDate) || entryDate.isBefore(endDate));
          }
          return matchesSearch && matchesDate;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF1F2F6),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(book, provider),
                SliverToBoxAdapter(child: FadeInDown(child: _buildSummaryCard(provider))),
                SliverToBoxAdapter(child: _buildFilterBar()),
                if (_isCloudConnected) SliverToBoxAdapter(child: _buildSyncStatusBadge()),
                SliverToBoxAdapter(child: _buildPrivacyBanner()),
              ];
            },
            body: Column(
              children: [
                if (filteredList.isEmpty && !isLoading)
                  _buildEmptyState(isFiltered: _searchQuery.isNotEmpty || _selectedDateRange != null)
                else
                  Expanded(child: _buildTransactionList(filteredList)),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomEntryBar(book.id!),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BookModel book, TransactionProvider provider) {
    return SliverAppBar(
      pinned: true,
      elevation: 0.5,
      backgroundColor: Colors.white,
      expandedHeight: 60,
      leading: _isSearching 
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => setState(() {
              _isSearching = false;
              _searchQuery = "";
              _searchController.clear();
            }),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEEF2FF),
              backgroundImage: _googlePhoto != null ? NetworkImage(_googlePhoto!) : null,
              child: _googlePhoto == null ? const Icon(Icons.person, color: Color(0xFF6366F1), size: 20) : null,
            ),
          ),
      title: _isSearching
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search entries...',
              border: InputBorder.none,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Tap here for Book settings', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () => setState(() => _isSearching = true),
          ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF6366F1)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportScreen(
                transactions: provider.transactions,
                bookName: provider.currentBook?.name ?? "My Cashbook",
              ),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {}),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(Icons.calendar_month, size: 16, color: _selectedDateRange != null ? Colors.white : Colors.grey),
            label: Text(_selectedDateRange == null ? 'All Time' : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}'),
            backgroundColor: _selectedDateRange != null ? const Color(0xFF6366F1) : Colors.white,
            labelStyle: TextStyle(color: _selectedDateRange != null ? Colors.white : Colors.black87),
            onPressed: _showDateRangePicker,
          ),
          if (_selectedDateRange != null)
            IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _selectedDateRange = null)),
          const Spacer(),
          Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1))),
        child: child!,
      ),
    );
    if (range != null) setState(() => _selectedDateRange = range);
  }

  Widget _buildSummaryCard(TransactionProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(formatCurrency(provider.balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total In (+)', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text(formatCurrency(provider.totalCashIn), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Out (-)', style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text(formatCurrency(provider.totalCashOut), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock, color: Colors.green, size: 14),
          SizedBox(width: 8),
          Text('Only you can see these entries', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final trans = list[index];
        return TransactionCard(
          transaction: trans,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionDetailScreen(transaction: trans))),
        );
      },
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(isFiltered ? 'No entries found for this filter' : 'Add your first entry', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          if (isFiltered)
            TextButton(
              onPressed: () => setState(() {
                _searchQuery = "";
                _selectedDateRange = null;
                _searchController.clear();
              }),
              child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF6366F1))),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomEntryBar(int bookId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(child: _buildEntryButton(bookId, TransactionType.cashIn, 'Record Income', 'CASH IN', Colors.green[700]!)),
          const SizedBox(width: 16),
          Expanded(child: _buildEntryButton(bookId, TransactionType.cashOut, 'Record Expense', 'CASH OUT', Colors.red[700]!)),
        ],
      ),
    );
  }

  Widget _buildEntryButton(int bookId, TransactionType type, String label, String btnText, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(bookId: bookId, initialType: type))),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          icon: Icon(type == TransactionType.cashIn ? Icons.add : Icons.remove),
          label: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSyncStatusBadge() {
    String syncText = 'Not backed up yet';
    if (_lastBackup != null) {
      try {
        final dt = DateTime.parse(_lastBackup!);
        syncText = 'Last sync: ${DateFormat('dd MMM, hh:mm a').format(dt)}';
      } catch (_) {}
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_done_outlined, color: Colors.blue, size: 14),
          const SizedBox(width: 6),
          Text(syncText, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
