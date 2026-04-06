import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'package:intl/intl.dart';

class ReportRow {
  final String label;
  final double cashIn;
  final double cashOut;
  final double balance;
  final String? extra;

  ReportRow({
    required this.label,
    required this.cashIn,
    required this.cashOut,
    required this.balance,
    this.extra,
  });
}

class ReportService {
  static List<ReportRow> _getGroupedData(List<TransactionModel> transactions, String reportType) {
    if (reportType == 'All Entries Report') return [];

    final Map<String, List<TransactionModel>> groups = {};

    for (var t in transactions) {
      String key = '';
      if (reportType == 'Day-wise summary') {
        key = DateFormat('dd MMM yyyy').format(t.date);
      } else if (reportType == 'Contact-wise summary') {
        key = t.partyName ?? 'No Contact';
      } else if (reportType == 'Category-wise summary') {
        key = t.category;
      } else if (reportType == 'Payment Modes summary') {
        key = t.paymentMode; 
      }

      groups.putIfAbsent(key, () => []).add(t);
    }

    double runningBalance = 0;
    return groups.entries.map((e) {
      double inc = 0;
      double out = 0;
      for (var t in e.value) {
        if (t.type == TransactionType.cashIn) inc += t.amount;
        else out += t.amount;
      }
      runningBalance += (inc - out);
      return ReportRow(
        label: e.key,
        cashIn: inc,
        cashOut: out,
        balance: runningBalance,
      );
    }).toList();
  }

  static Future<String> generatePdf({
    required List<TransactionModel> transactions,
    required String bookName,
    required Map<String, bool> settings,
    required String reportType,
    String? businessName,
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final isDetail = reportType == 'All Entries Report';
    
    // Calculate Totals
    double totalIn = 0;
    double totalOut = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.cashIn) totalIn += t.amount;
      else totalOut += t.amount;
    }
    double netBalance = totalIn - totalOut;

    final headers = <String>[];
    if (isDetail) {
      if (settings['Date'] ?? true) headers.add('Date');
      if (settings['Remark'] ?? true) headers.add('Remark');
      if (settings['Category'] ?? true) headers.add('Category');
      if (settings['Party Name'] ?? true) headers.add('Party');
      if (settings['Cash In'] ?? true) headers.add('Cash In');
      if (settings['Cash Out'] ?? true) headers.add('Cash Out');
      if (settings['Balance'] ?? true) headers.add('Balance');
    } else {
      headers.addAll(['Group / Name', 'Cash In', 'Cash Out', 'Balance']);
    }

    final List<List<String>> rowData = [];
    if (isDetail) {
      double bal = 0;
      for (var t in transactions) {
        if (t.type == TransactionType.cashIn) bal += t.amount; else bal -= t.amount;
        final row = <String>[];
        if (settings['Date'] ?? true) row.add(DateFormat('dd MMM yyyy').format(t.date));
        if (settings['Remark'] ?? true) row.add(t.note ?? '-');
        if (settings['Category'] ?? true) row.add(t.category);
        if (settings['Party Name'] ?? true) row.add(t.partyName ?? '-');
        if (settings['Cash In'] ?? true) row.add(t.type == TransactionType.cashIn ? formatCurrency(t.amount) : '');
        if (settings['Cash Out'] ?? true) row.add(t.type == TransactionType.cashOut ? formatCurrency(t.amount) : '');
        if (settings['Balance'] ?? true) row.add(formatCurrency(bal));
        rowData.add(row);
      }
    } else {
      final grouped = _getGroupedData(transactions, reportType);
      for (var r in grouped) {
        rowData.add([r.label, formatCurrency(r.cashIn), formatCurrency(r.cashOut), formatCurrency(r.balance)]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoPath != null && File(logoPath).existsSync())
                        pw.Container(
                          width: 45,
                          height: 45,
                          margin: const pw.EdgeInsets.only(right: 12),
                          child: pw.Image(pw.MemoryImage(File(logoPath).readAsBytesSync()), fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 45,
                          height: 45,
                          margin: const pw.EdgeInsets.only(right: 12),
                          decoration: const pw.BoxDecoration(color: PdfColors.indigo, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                          alignment: pw.Alignment.center,
                          child: pw.Text((businessName ?? bookName)[0].toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text((businessName ?? 'MY BUSINESS').toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                          pw.Text(bookName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                          pw.Text(reportType, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Report Generated On', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                    pw.Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Powered by Softgrid Solutions', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfSummaryItem('TOTAL CASH IN', totalIn, PdfColors.green),
                _buildPdfSummaryItem('TOTAL CASH OUT', totalOut, PdfColors.red),
                _buildPdfSummaryItem('NET BALANCE', netBalance, netBalance >= 0 ? PdfColors.indigo : PdfColors.red),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Data Table
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rowData.cast<List<dynamic>>(),
            border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 25,
            cellAlignments: { for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${bookName.replaceAll(' ', '_')}_${DateFormat('dd-MM-yyyy_HH-mm-ss').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> generateSingleTransactionPdf({
    required TransactionModel transaction,
    String? businessName,
    String? logoPath,
  }) async {
    final pdf = pw.Document();
    final isCashIn = transaction.type == TransactionType.cashIn;
    final primaryColor = isCashIn ? PdfColors.green700 : PdfColors.red700;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(400, 500, marginAll: 0),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          color: PdfColors.white,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Blue Top Border (from image)
              pw.Container(
                height: 10,
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.indigo,
                  borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(10)),
                ),
              ),
              pw.SizedBox(height: 15),

              // Title Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  pw.Text('Bill Date: ${DateFormat('dd MMM yyyy').format(transaction.date)}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey100),
              pw.SizedBox(height: 20),

              // Payment Mode
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Mode', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey500)),
                    pw.Text(transaction.paymentMode, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('Amount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
              ),

              // Table Body
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(transaction.partyName ?? 'General Entry', style: pw.TextStyle(fontSize: 16, color: PdfColors.black)),
                        if (transaction.note != null && transaction.note!.isNotEmpty)
                          pw.Text(transaction.note!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                      ],
                    ),
                    pw.Text(
                      '${isCashIn ? '+' : '-'} ${formatCurrency(transaction.amount)}'.replaceAll('RS.', '').trim(), 
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor)
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey100),

              // Custom Fields if any
              if (transaction.customFields != null && transaction.customFields!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                ...transaction.customFields!.entries.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(e.key, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.Text(e.value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ],

              pw.Spacer(),

              // Footer (from image)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Created by', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                    pw.SizedBox(height: 5),
                    
                    // App Branding (CASHBOOK Logo Style)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 20, height: 20,
                            decoration: const pw.BoxDecoration(color: PdfColors.blue, shape: pw.BoxShape.circle),
                            alignment: pw.Alignment.center,
                            child: pw.Text('C', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('CASHBOOK', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              pw.Text('Easy to Use | 100% Safe', style: pw.TextStyle(fontSize: 6, color: PdfColors.blue700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Powered by Softgrid Solutions', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'Receipt_${transaction.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> generateExcel({
    required List<TransactionModel> transactions,
    required String bookName,
    required Map<String, bool> settings,
    required String reportType,
    String? businessName,
  }) async {
    final xls.Workbook workbook = xls.Workbook();
    final xls.Worksheet sheet = workbook.worksheets[0];
    final isDetail = reportType == 'All Entries Report';

    // Set Title
    sheet.getRangeByName('A1').setText((businessName ?? bookName).toUpperCase());
    sheet.getRangeByName('A1').cellStyle.fontSize = 16;
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.fontColor = '#1E1B4B'; // Indigo 900

    sheet.getRangeByName('A2').setText("$bookName - $reportType");
    sheet.getRangeByName('A2').cellStyle.fontSize = 12;
    sheet.getRangeByName('A2').cellStyle.fontColor = '#4B5563'; // Grey 600

    // Headers start from row 4
    final headers = <String>[];
    if (isDetail) {
      if (settings['Date'] ?? true) headers.add('Date');
      if (settings['Remark'] ?? true) headers.add('Remark');
      if (settings['Category'] ?? true) headers.add('Category');
      if (settings['Party Name'] ?? true) headers.add('Party');
      if (settings['Cash In'] ?? true) headers.add('Cash In');
      if (settings['Cash Out'] ?? true) headers.add('Cash Out');
      if (settings['Balance'] ?? true) headers.add('Balance');
    } else {
      headers.addAll(['Group / Label', 'Cash In', 'Cash Out', 'Net Balance']);
    }

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(4, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.backColor = '#4338CA'; // Indigo 700
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.bold = true;
      cell.cellStyle.hAlign = xls.HAlignType.center;
    }

    if (isDetail) {
      double bal = 0;
      for (var r = 0; r < transactions.length; r++) {
        final t = transactions[r];
        if (t.type == TransactionType.cashIn) bal += t.amount; else bal -= t.amount;
        int col = 1;
        if (settings['Date'] ?? true) sheet.getRangeByIndex(r + 5, col++).setDateTime(t.date);
        if (settings['Remark'] ?? true) sheet.getRangeByIndex(r + 5, col++).setText(t.note ?? '');
        if (settings['Category'] ?? true) sheet.getRangeByIndex(r + 5, col++).setText(t.category);
        if (settings['Party Name'] ?? true) sheet.getRangeByIndex(r + 5, col++).setText(t.partyName ?? '');
        if (settings['Cash In'] ?? true) sheet.getRangeByIndex(r + 5, col++).setNumber(t.type == TransactionType.cashIn ? t.amount : 0);
        if (settings['Cash Out'] ?? true) sheet.getRangeByIndex(r + 5, col++).setNumber(t.type == TransactionType.cashOut ? t.amount : 0);
        if (settings['Balance'] ?? true) sheet.getRangeByIndex(r + 5, col++).setNumber(bal);
      }
    } else {
      final grouped = _getGroupedData(transactions, reportType);
      for (var r = 0; r < grouped.length; r++) {
        final row = grouped[r];
        sheet.getRangeByIndex(r + 5, 1).setText(row.label);
        sheet.getRangeByIndex(r + 5, 2).setNumber(row.cashIn);
        sheet.getRangeByIndex(r + 5, 3).setNumber(row.cashOut);
        sheet.getRangeByIndex(r + 5, 4).setNumber(row.balance);
      }
    }

    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
        sheet.autoFitColumn(i);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${bookName.replaceAll(' ', '_')}_${DateFormat('dd-MM-yyyy_HH-mm-ss').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> shareFile(String path, {String text = 'Exported Ledger'}) async {
    if (File(path).existsSync()) {
      await Share.shareXFiles([XFile(path)], text: text);
    }
  }

  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }

  static pw.Widget _buildPdfSummaryItem(String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.SizedBox(height: 4),
        pw.Text(formatCurrency(value), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
