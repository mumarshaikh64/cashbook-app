import 'package:intl/intl.dart';
import '../utils/formatters.dart';

enum TransactionType { cashIn, cashOut }

class TransactionModel {
  final int? id;
  final int bookId; // Associated Book ID
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String? note;
  final String? attachmentPath;
  final String? partyName; // Who gave or who was given to
  final int isSynced;

  TransactionModel({
    this.id,
    required this.bookId,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.category = 'General',
    this.note,
    this.attachmentPath,
    this.partyName,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.index,
      'category': category,
      'note': note,
      'attachmentPath': attachmentPath,
      'partyName': partyName,
      'isSynced': isSynced,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      bookId: map['bookId'] ?? 0,
      title: map['title'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      type: TransactionType.values[map['type']],
      category: map['category'] ?? 'General',
      note: map['note'],
      attachmentPath: map['attachmentPath'],
      partyName: map['partyName'],
      isSynced: map['isSynced'] ?? 0,
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(date);
  String get formattedAmount => formatCurrency(amount);
}
