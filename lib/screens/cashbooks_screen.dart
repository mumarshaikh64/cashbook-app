import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_provider.dart';
import '../models/book.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';
import 'help_screen.dart';
import '../utils/formatters.dart';
import '../widgets/custom_modals.dart';

class CashbooksScreen extends StatefulWidget {
  @override
  _CashbooksScreenState createState() => _CashbooksScreenState();
}

class _CashbooksScreenState extends State<CashbooksScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TransactionProvider>().fetchBooks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 2 ? null : _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildBody(),
          const HelpScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0 ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final businessName =
        context.watch<AppProvider>().businessName ?? 'Softgrid Solutions';

    if (_isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => setState(() {
            _isSearching = false;
            _searchQuery = "";
            _searchController.clear();
          }),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search books...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange == null
                  ? Icons.filter_list
                  : Icons.filter_list_off,
              color: const Color(0xFF6366F1),
            ),
            onPressed: _showDateRangePicker,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => _searchController.clear(),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.business_outlined, color: Colors.grey),
        ),
      ),
      title: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text(
              'Tap to switch business',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_selectedIndex == 0) ...[
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF6366F1)),
            onPressed: () => setState(() => _isSearching = true),
          ),
          IconButton(
            icon: Icon(
              _selectedDateRange == null
                  ? Icons.filter_list
                  : Icons.filter_list_off,
              color: const Color(0xFF6366F1),
            ),
            onPressed: _showDateRangePicker,
          ),
        ],
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () {
              context.read<AppProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => SplashScreen()),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final filteredBooks = provider.books.where((b) {
          final matchesSearch = b.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          bool matchesDate = true;
          if (_selectedDateRange != null) {
            final bDate = DateTime(
              b.createdAt.year,
              b.createdAt.month,
              b.createdAt.day,
            );
            final sDate = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final eDate = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
            );
            matchesDate =
                (bDate.isAtSameMomentAs(sDate) || bDate.isAfter(sDate)) &&
                (bDate.isAtSameMomentAs(eDate) || bDate.isBefore(eDate));
          }
          return matchesSearch && matchesDate;
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isSearching) _buildPromotionalBanner(),
              _buildSectionHeader(),
              if (filteredBooks.isEmpty && !provider.isLoading)
                _buildEmptyState(
                  isFiltered:
                      _searchQuery.isNotEmpty || _selectedDateRange != null,
                )
              else
                _buildBooksList(filteredBooks),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromotionalBanner() {
    return FadeIn(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basics of CashBook',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Learn to use cashbook',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Know more',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.amberAccent,
                  size: 60,
                ),
              ],
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Your Books',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Chip(
                label: Text(
                  '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 11),
                ),
                onDeleted: () => setState(() => _selectedDateRange = null),
                deleteIcon: const Icon(Icons.close, size: 14),
              ),
            ),
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
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() => _selectedDateRange = range);
  }

  Widget _buildBooksList(List<BookModel> books) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () {
              context.read<TransactionProvider>().setCurrentBook(book);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEEF2FF),
              child: const Icon(Icons.bookmark, color: Color(0xFF6366F1)),
            ),
            title: Text(
              book.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Created ${book.createdAt.day}/${book.createdAt.month}/${book.createdAt.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatCurrency(book.cashIn),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      formatCurrency(book.cashOut),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  offset: const Offset(0, 40),
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _showRenameDialog(book.id!, book.name);
                        break;
                      case 'duplicate':
                        context.read<TransactionProvider>().createBook(
                          '${book.name} (Copy)',
                        );
                        break;
                      case 'delete':
                        _confirmDelete(book.id!, book.name);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    _menuItem(
                      'rename',
                      Icons.edit_outlined,
                      'Rename',
                      Colors.black87,
                    ),
                    _menuItem(
                      'duplicate',
                      Icons.copy_all_outlined,
                      'Duplicate Book',
                      Colors.black87,
                    ),
                    const PopupMenuDivider(height: 1),
                    _menuItem(
                      'delete',
                      Icons.delete_outline_rounded,
                      'Delete Book',
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      height: 44,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(int bookId, String currentName) {
    final controller = TextEditingController(text: currentName);
    CustomModals.showPremiumBottomSheet(
      context: context,
      title: 'Rename Book',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update your cashbook name below.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Book Name',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await context.read<TransactionProvider>().renameBook(
                          bookId,
                          controller.text,
                        );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'UPDATE NAME',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int bookId, String bookName) {
    final TextEditingController deleteController = TextEditingController();
    bool isMatch = false;

    CustomModals.showPremiumBottomSheet(
      context: context,
      title: 'Delete Book',
      child: StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD32F2F), size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This action is permanent and will delete all entries in this book.',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'To confirm, please type '),
                    TextSpan(
                      text: bookName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444)),
                    ),
                    const TextSpan(text: ' below.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deleteController,
                autofocus: true,
                onChanged: (value) {
                  setModalState(() {
                    isMatch = value == bookName;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Enter book name',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFEF4444), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isMatch
                      ? () {
                          context.read<TransactionProvider>().deleteBook(bookId);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[400],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'DELETE PERMANENTLY',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.book_outlined,
              size: 60,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No business books found' : 'No books yet. Add one!',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: _showAddBookDialog,
        backgroundColor: const Color(0xFF6366F1),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'ADD NEW BOOK',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.book_outlined,
        'activeIcon': Icons.book_rounded,
        'label': 'Cashbooks',
      },
      {
        'icon': Icons.help_outline_rounded,
        'activeIcon': Icons.help_rounded,
        'label': 'Help',
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings_rounded,
        'label': 'Settings',
      },
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = _selectedIndex == index;
          final item = items[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20 : 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? item['activeIcon'] as IconData
                        : item['icon'] as IconData,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.grey[500],
                    size: 22,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isSelected
                        ? Row(
                            children: [
                              const SizedBox(width: 6),
                              Text(
                                item['label'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showAddBookDialog() {
    final controller = TextEditingController();
    CustomModals.showPremiumBottomSheet(
      context: context,
      title: 'Add New Book',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give your cashbook a name to get started.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Book Name',
                hintText: 'e.g. My General Store',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    context.read<TransactionProvider>().createBook(
                          controller.text,
                        );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'CREATE CASHBOOK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
