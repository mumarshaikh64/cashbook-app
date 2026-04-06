import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/report_service.dart';
import '../utils/formatters.dart';
import '../widgets/receipt_clipper.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _captureAndShareImage(TransactionModel transaction) async {
    try {
      // Show loading indicator
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      
      RenderRepaintBoundary boundary = _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.5); // Higher quality for better WP sharing
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = (await getTemporaryDirectory()).path;
      final fileName = 'Receipt_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imgFile = File('$directory/$fileName');
      await imgFile.writeAsBytes(pngBytes);

      Navigator.pop(context); // Close loading indicator
      
      await ReportService.shareFile(imgFile.path, text: 'Attached: ${transaction.title} Bill Receipt');
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currentTransaction = provider.transactions.firstWhere(
          (t) => t.id == widget.transaction.id,
          orElse: () => widget.transaction,
        );
        
        final isCashIn = currentTransaction.type == TransactionType.cashIn;
        final primaryColor = isCashIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Entry Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTransactionScreen(bookId: currentTransaction.bookId, transaction: currentTransaction)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, currentTransaction.id!),
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── HIDDEN CAPTURE AREA ──
              Positioned(
                left: -2000, 
                top: 0,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    width: 380,
                    color: Colors.white,
                    child: ClipPath(
                      clipper: ReceiptPaperClipper(),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(25, 45, 25, 35),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Bill', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Bill Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(DateFormat('dd MMM yyyy').format(currentTransaction.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 35, thickness: 1, color: Color(0xFFF3F4F6)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Mode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(currentTransaction.paymentMode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 35),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                  Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(currentTransaction.partyName ?? 'General Entry', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                      if (currentTransaction.note != null && currentTransaction.note!.isNotEmpty)
                                        Text(currentTransaction.note!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCashIn ? '+' : '-'} ${formatCurrency(currentTransaction.amount).replaceAll('RS.', '').trim()}',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor),
                                ),
                              ],
                            ),
                            const Divider(height: 45, thickness: 1, color: Color(0xFFF3F4F6)),
                            if (currentTransaction.customFields != null && currentTransaction.customFields!.isNotEmpty) ...[
                              ...currentTransaction.customFields!.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )).toList(),
                              const SizedBox(height: 25),
                            ],
                            Center(
                              child: Column(
                                children: [
                                  const Text('Created by', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 10),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)), borderRadius: BorderRadius.circular(7)), child: Row(mainAxisSize: MainAxisSize.min, children: [const CircleAvatar(radius: 11, backgroundColor: Color(0xFF6366F1), child: Text('C', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CASHBOOK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))), Text('Easy to Use | 100% Safe', style: TextStyle(fontSize: 7, color: Colors.grey[500]))])])),
                                  const SizedBox(height: 15),
                                  const Text('Powered by Softgrid Solutions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 1.0), // Tiny spacer to keep height valid
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── MAIN SCREEN VIEW ──
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), border: Border(bottom: BorderSide(color: primaryColor.withOpacity(0.1)))),
                            child: Column(
                              children: [
                                Text(isCashIn ? 'Cash In' : 'Cash Out', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(formatCurrency(currentTransaction.amount), style: TextStyle(color: primaryColor, fontSize: 36, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(DateFormat('dd MMM yyyy, hh:mm a').format(currentTransaction.date), style: const TextStyle(color: Colors.grey, fontSize: 13))]),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (currentTransaction.partyName != null && currentTransaction.partyName!.isNotEmpty) ...[
                                  _detailRow(Icons.person_outline, isCashIn ? 'Received From' : 'Paid To', currentTransaction.partyName!),
                                  const SizedBox(height: 24),
                                ],
                                _detailRow(Icons.category_outlined, 'Category', currentTransaction.category),
                                const SizedBox(height: 24),
                                _detailRow(Icons.payments_outlined, 'Payment Mode', currentTransaction.paymentMode),
                                const SizedBox(height: 24),
                                if (currentTransaction.reference != null && currentTransaction.reference!.isNotEmpty) ...[
                                  _detailRow(Icons.receipt_long_outlined, 'Reference / Invoice', currentTransaction.reference!),
                                  const SizedBox(height: 24),
                                ],
                                if (currentTransaction.customFields != null) ...[
                                  ...currentTransaction.customFields!.entries.map((entry) => Column(children: [_detailRow(Icons.label_important_outline, entry.key, entry.value), const SizedBox(height: 24)])).toList(),
                                ],
                                _detailRow(Icons.description_outlined, 'Remarks', currentTransaction.note ?? 'No remarks'),
                                const SizedBox(height: 24),
                                if (currentTransaction.attachmentPath != null && currentTransaction.attachmentPath!.isNotEmpty) ...[
                                  const Text('Attachment', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => _viewImage(context, currentTransaction.attachmentPath!),
                                    child: Container(
                                      height: 200, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                                      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(currentTransaction.attachmentPath!), fit: BoxFit.cover)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // WhatsApp / Share Button at Bottom
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                    child: ElevatedButton.icon(
                      onPressed: () => _captureAndShareImage(currentTransaction),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('SEND BILL ON WHATSAPP / OTHER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Colors.grey[400]), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))]))]);
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Delete Entry?'), content: const Text('Are you sure you want to delete this entry?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')), TextButton(onPressed: () async { await context.read<TransactionProvider>().deleteTransaction(id); Navigator.pop(context); Navigator.pop(context); }, child: const Text('DELETE', style: TextStyle(color: Colors.red)))]));
  }

  void _viewImage(BuildContext context, String path) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.file(File(path)))));
  }
}
