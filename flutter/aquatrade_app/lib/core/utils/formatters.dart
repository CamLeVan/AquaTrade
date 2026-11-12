import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(double amount) {
    final formatString = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatString.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatNumber(num value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }
}
