import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final int bookId;
  final TransactionType initialType;
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, required this.bookId, this.initialType = TransactionType.cashIn, this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _partyController = TextEditingController();
  
  late TransactionType _type;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'General';
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
      _selectedDate = widget.transaction!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
      _selectedCategory = widget.transaction!.category;
      if (widget.transaction!.attachmentPath != null) {
        _attachment = File(widget.transaction!.attachmentPath!);
      }
    } else {
      _type = widget.initialType;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _attachment = File(picked.path));
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _remarkController.text = val.recognizedWords;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showPartyPicker(TextEditingController autocompleteController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Consumer<TransactionProvider>(
        builder: (context, provider, child) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Party', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF6366F1)),
                    onPressed: () => _showAddPartyDialog(autocompleteController),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: provider.parties.isEmpty 
                  ? const Center(child: Text('No parties added yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                    itemCount: provider.parties.length,
                    itemBuilder: (context, index) {
                      final party = provider.parties[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline, size: 20)),
                        title: Text(party),
                        onTap: () {
                          autocompleteController.text = party;
                          _partyController.text = party;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPartyDialog(TextEditingController autocompleteController) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Party'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Party Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
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
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    final provider = context.read<TransactionProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1)),
                    onPressed: () => _showAddCategoryDialog(setModalState),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final cat = provider.categories[index];
                    return ListTile(
                      title: Text(cat),
                      leading: const Icon(Icons.category_outlined, size: 20),
                      trailing: _selectedCategory == cat ? const Icon(Icons.check_circle, color: Color(0xFF6366F1)) : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(Function setModalState) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Category Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await context.read<TransactionProvider>().addCategory(ctrl.text);
                setModalState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = _type == TransactionType.cashIn;
    final primaryColor = isCashIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final partyList = context.watch<TransactionProvider>().parties;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(isCashIn ? 'Add Cash In' : 'Add Cash Out', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
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
                                  builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)), child: child!),
                                );
                                if (date != null) setState(() => _selectedDate = date);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('dd MMM, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 20, color: Colors.grey[300]),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                  builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)), child: child!),
                                );
                                if (time != null) setState(() => _selectedTime = time);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(_selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Party Name Field (Autocomplete + Button) ──
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        return partyList.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) => _partyController.text = selection,
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (v) => _partyController.text = v,
                          decoration: InputDecoration(
                            labelText: isCashIn ? 'From (Person/Party)' : 'To (Person/Party)',
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1)),
                              onPressed: () => _showPartyPicker(controller),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
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
                                  final String option = options.elementAt(index);
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                        child: Row(
                          children: [
                            const Icon(Icons.category_outlined, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_selectedCategory, style: const TextStyle(fontSize: 16))),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _remarkController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Remarks (Optional)',
                        hintText: 'Enter details here...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        suffixIcon: IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: const Color(0xFF6366F1)),
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
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_attachment!, fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 14,
                              child: IconButton(icon: const Icon(Icons.close, size: 14, color: Colors.white), onPressed: () => setState(() => _attachment = null)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onSave(context, andNew: true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50), 
                      side: const BorderSide(color: Color(0xFF6366F1)), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                    ),
                    child: const Text('SAVE & NEW', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onSave(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50), 
                      backgroundColor: const Color(0xFF6366F1), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                    ),
                    child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        bookId: widget.bookId,
        title: _partyController.text.isNotEmpty ? _partyController.text : (_remarkController.text.isEmpty ? 'Entry' : _remarkController.text),
        amount: double.parse(_amountController.text),
        type: _type,
        date: combinedDate,
        category: _selectedCategory,
        note: _remarkController.text,
        partyName: _partyController.text,
        attachmentPath: _attachment?.path,
      );

      if (widget.transaction != null) {
        await context.read<TransactionProvider>().updateTransaction(transaction);
      } else {
        await context.read<TransactionProvider>().addTransaction(transaction);
      }

      if (andNew) {
        setState(() {
          _amountController.clear();
          _remarkController.clear();
          _partyController.clear();
          _attachment = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved! Add next one.')));
      } else {
        Navigator.pop(context);
      }
    }
  }
}
