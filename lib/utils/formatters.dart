import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  if (amount >= 1000) {
    double kValue = amount / 1000;
    // Show one decimal place if not a whole number (e.g. 1.5k), otherwise just 1k
    String formatted = kValue.toStringAsFixed(kValue.truncateToDouble() == kValue ? 0 : 1);
    return '₨ ${formatted}k';
  } else if (amount <= -1000) {
    double kValue = amount / 1000;
    String formatted = kValue.abs().toStringAsFixed(kValue.truncateToDouble() == kValue ? 0 : 1);
    return '-₨ ${formatted}k';
  }
  return NumberFormat.currency(symbol: '₨ ', decimalDigits: 0).format(amount);
}
