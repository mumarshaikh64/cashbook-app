import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/custom_modals.dart';

class CustomFieldController {
  final TextEditingController label;
  final TextEditingController value;
  CustomFieldController({required this.label, required this.value});
}

class AddTransactionScreen extends StatefulWidget {
  final int bookId;
  final TransactionType initialType;
  final TransactionModel? transaction;

  const AddTransactionScreen({
    super.key,
    required this.bookId,
    this.initialType = TransactionType.cashIn,
    this.transaction,
  });

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _partyController = TextEditingController();
  final _referenceController = TextEditingController();

  final List<CustomFieldController> _customFieldControllers = [];

  late TransactionType _type;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'General';
  String _selectedPaymentMode = 'Cash';
  File? _attachment;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _amountController.text = widget.transaction!.amount.toString();
      _remarkController.text = widget.transaction!.note ?? "";
      _partyController.text = widget.transaction!.partyName ?? "";
      _referenceController.text = widget.transaction!.reference ?? "";
      _selectedDate = widget.transaction!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
      _selectedCategory = widget.transaction!.category;
      _selectedPaymentMode = widget.transaction!.paymentMode;
      if (widget.transaction!.attachmentPath != null) {
        _attachment = File(widget.transaction!.attachmentPath!);
      }

      // Load custom fields
      if (widget.transaction!.customFields != null) {
        widget.transaction!.customFields!.forEach((k, v) {
          _customFieldControllers.add(
            CustomFieldController(
              label: TextEditingController(text: k),
              value: TextEditingController(text: v),
            ),
          );
        });
      }
    } else {
      _type = widget.initialType;
    }
  }

  void _addCustomField() {
    setState(() {
      _customFieldControllers.add(
        CustomFieldController(
          label: TextEditingController(),
          value: TextEditingController(),
        ),
      );
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFieldControllers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _attachment = File(picked.path));
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        final String currentText = _remarkController.text;
        _speech.listen(
          onResult: (val) {
            setState(() {
              if (currentText.isEmpty) {
                _remarkController.text = val.recognizedWords;
              } else {
                _remarkController.text = '$currentText ${val.recognizedWords}';
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showPartyPicker(TextEditingController autocompleteController) {
    CustomModals.showPremiumBottomSheet(
      context: context,
      title: 'Select Party',
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search or add a person/party',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddPartyDialog(autocompleteController),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('New Party'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1)),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: provider.parties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 64, color: Colors.grey[200]),
                          const SizedBox(height: 16),
                          const Text(
                            'No parties added yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: provider.parties.length,
                      itemBuilder: (context, index) {
                        final party = provider.parties[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF3F4F6),
                              child: Text(party[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(party,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              autocompleteController.text = party;
                              _partyController.text = party;
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartyDialog(TextEditingController autocompleteController) {
    final ctrl = TextEditingController();
    CustomModals.showPremiumDialog(
      context: context,
      title: 'Add New Party',
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Party Name',
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () async {
            if (ctrl.text.isNotEmpty) {
              await context.read<TransactionProvider>().addParty(ctrl.text);
              autocompleteController.text = ctrl.text;
              _partyController.text = ctrl.text;
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('ADD PARTY'),
        ),
      ],
    );
  }

  void _showCategoryPicker() {
    final provider = context.read<TransactionProvider>();
    CustomModals.showPremiumBottomSheet(
      context: context,
      title: 'Select Category',
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose a category for this entry',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(setModalState),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('New'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1)),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final cat = provider.categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEEF2FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(cat,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF4338CA)
                                : Colors.black87,
                          )),
                      leading: Icon(Icons.category_outlined,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF6366F1))
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(Function setModalState) {
    final ctrl = TextEditingController();
    CustomModals.showPremiumDialog(
      context: context,
      title: 'New Category',
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Category Name',
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () async {
            if (ctrl.text.isNotEmpty) {
              await context.read<TransactionProvider>().addCategory(
                    ctrl.text,
                  );
              setModalState(() {});
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('ADD'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = _type == TransactionType.cashIn;
    final primaryColor = isCashIn
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final partyList = context.watch<TransactionProvider>().parties;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCashIn ? 'Add Cash In' : 'Add Cash Out',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Date & Time Row ──────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (date != null)
                                  setState(() => _selectedDate = date);
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'dd MMM, yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null)
                                  setState(() => _selectedTime = time);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Amount Field ─────────────────────
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Party Name Field (Autocomplete + Button) ──
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        return partyList.where(
                          (String option) => option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (String selection) =>
                          _partyController.text = selection,
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: (v) => _partyController.text = v,
                              decoration: InputDecoration(
                                labelText: isCashIn
                                    ? 'From (Person/Party) (Optional)'
                                    : 'To (Person/Party) (Optional)',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Colors.grey,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFF6366F1),
                                  ),
                                  onPressed: () => _showPartyPicker(controller),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 200,
                              color: Colors.white,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Category Selector ────────────────
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Payment Mode ─────────────────────
                    const Text(
                      'Payment Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Cash', 'Bank', 'Other']
                            .map(
                              (mode) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(mode),
                                  selected: _selectedPaymentMode == mode,
                                  selectedColor: primaryColor.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: _selectedPaymentMode == mode
                                        ? primaryColor
                                        : Colors.black87,
                                    fontWeight: _selectedPaymentMode == mode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (bool selected) {
                                    if (selected)
                                      setState(
                                        () => _selectedPaymentMode = mode,
                                      );
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Reference Field ──────────────────
                    TextFormField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        labelText: 'Reference / Invoice No. (Optional)',
                        prefixIcon: const Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── DYNAMIC CUSTOM FIELDS ──────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Fields',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addCustomField,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Add Field'),
                        ),
                      ],
                    ),
                    ..._customFieldControllers.asMap().entries.map((entry) {
                      int idx = entry.key;
                      CustomFieldController ctrl = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: ctrl.label,
                                decoration: InputDecoration(
                                  hintText: 'Field Name (e.g. Driver)',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: TextField(
                                controller: ctrl.value,
                                decoration: InputDecoration(
                                  hintText: 'Enter Value',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeCustomField(idx),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (_customFieldControllers.isNotEmpty)
                      const SizedBox(height: 20),

                    TextFormField(
                      controller: _remarkController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Remarks (Optional)',
                        hintText: 'Enter details here...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: const Color(0xFF6366F1),
                          ),
                          onPressed: _listen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Attachment ───────────────────────
                    if (_attachment != null)
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _attachment!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 14,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _attachment = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Add Attachment'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onSave(context, andNew: true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'SAVE & NEW',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onSave(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSave(BuildContext context, {bool andNew = false}) async {
    if (_formKey.currentState!.validate()) {
      final combinedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Collect dynamic fields
      final Map<String, String> customFieldsData = {};
      for (var ctrl in _customFieldControllers) {
        if (ctrl.label.text.isNotEmpty && ctrl.value.text.isNotEmpty) {
          customFieldsData[ctrl.label.text] = ctrl.value.text;
        }
      }

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        bookId: widget.bookId,
        title: _partyController.text.isNotEmpty
            ? _partyController.text
            : (_remarkController.text.isEmpty
                  ? 'Entry'
                  : _remarkController.text),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        type: _type,
        date: combinedDate,
        category: _selectedCategory,
        note: _remarkController.text,
        partyName: _partyController.text,
        paymentMode: _selectedPaymentMode,
        reference: _referenceController.text,
        customFields: customFieldsData.isEmpty ? null : customFieldsData,
        attachmentPath: _attachment?.path,
      );

      if (widget.transaction != null) {
        await context.read<TransactionProvider>().updateTransaction(
          transaction,
        );
      } else {
        await context.read<TransactionProvider>().addTransaction(transaction);
      }

      if (andNew) {
        setState(() {
          _amountController.clear();
          _remarkController.clear();
          _partyController.clear();
          _referenceController.clear();
          _customFieldControllers.clear();
          _attachment = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved! Add next one.')),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }
}
