import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    symbol: 'RS. ',
    decimalDigits: 0,
    locale: 'en_IN', // Keeping Indian digit grouping (e.g. 1,00,000) for local preference
  );
  return formatter.format(amount).trim();
}
