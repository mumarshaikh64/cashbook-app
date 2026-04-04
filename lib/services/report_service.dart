import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/transaction.dart';
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
    if (reportType == 'All Entries Report') return []; // Handled separately for detail

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
        key = 'Cash'; // Default mode
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
  }) async {
    final pdf = pw.Document();
    final isDetail = reportType == 'All Entries Report';
    
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
        if (settings['Date'] ?? true) row.add(DateFormat('dd MMM').format(t.date));
        if (settings['Remark'] ?? true) row.add(t.note ?? '-');
        if (settings['Category'] ?? true) row.add(t.category);
        if (settings['Party Name'] ?? true) row.add(t.partyName ?? '-');
        if (settings['Cash In'] ?? true) row.add(t.type == TransactionType.cashIn ? t.amount.toString() : '');
        if (settings['Cash Out'] ?? true) row.add(t.type == TransactionType.cashOut ? t.amount.toString() : '');
        if (settings['Balance'] ?? true) row.add(bal.toString());
        rowData.add(row);
      }
    } else {
      final grouped = _getGroupedData(transactions, reportType);
      for (var r in grouped) {
        rowData.add([r.label, r.cashIn.toString(), r.cashOut.toString(), r.balance.toString()]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(bookName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(reportType, style: const pw.TextStyle(color: PdfColors.grey)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rowData.cast<List<dynamic>>(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            cellHeight: 30,
            cellAlignments: { for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft },
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<String> generateExcel({
    required List<TransactionModel> transactions,
    required String bookName,
    required Map<String, bool> settings,
    required String reportType,
  }) async {
    final xls.Workbook workbook = xls.Workbook();
    final xls.Worksheet sheet = workbook.worksheets[0];
    final isDetail = reportType == 'All Entries Report';

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
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(1, i + 1).cellStyle.backColor = '#6366F1';
      sheet.getRangeByIndex(1, i + 1).cellStyle.fontColor = '#FFFFFF';
      sheet.getRangeByIndex(1, i + 1).cellStyle.bold = true;
    }

    if (isDetail) {
      double bal = 0;
      for (var r = 0; r < transactions.length; r++) {
        final t = transactions[r];
        if (t.type == TransactionType.cashIn) bal += t.amount; else bal -= t.amount;
        int col = 1;
        if (settings['Date'] ?? true) sheet.getRangeByIndex(r + 2, col++).setDateTime(t.date);
        if (settings['Remark'] ?? true) sheet.getRangeByIndex(r + 2, col++).setText(t.note ?? '');
        if (settings['Category'] ?? true) sheet.getRangeByIndex(r + 2, col++).setText(t.category);
        if (settings['Party Name'] ?? true) sheet.getRangeByIndex(r + 2, col++).setText(t.partyName ?? '');
        if (settings['Cash In'] ?? true) sheet.getRangeByIndex(r + 2, col++).setNumber(t.type == TransactionType.cashIn ? t.amount : 0);
        if (settings['Cash Out'] ?? true) sheet.getRangeByIndex(r + 2, col++).setNumber(t.type == TransactionType.cashOut ? t.amount : 0);
        if (settings['Balance'] ?? true) sheet.getRangeByIndex(r + 2, col++).setNumber(bal);
      }
    } else {
      final grouped = _getGroupedData(transactions, reportType);
      for (var r = 0; r < grouped.length; r++) {
        final row = grouped[r];
        sheet.getRangeByIndex(r + 2, 1).setText(row.label);
        sheet.getRangeByIndex(r + 2, 2).setNumber(row.cashIn);
        sheet.getRangeByIndex(r + 2, 3).setNumber(row.cashOut);
        sheet.getRangeByIndex(r + 2, 4).setNumber(row.balance);
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'Exported Ledger');
  }

  static Future<void> openFile(String path) async {
    await OpenFilex.open(path);
  }
}
