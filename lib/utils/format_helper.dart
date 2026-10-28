import 'package:intl/intl.dart';

class FormatHelper {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0", "en_US");
    String formatted = formatter.format(amount);

    // Apply your 5-digit limit requirement
    if (formatted.length > 6) {
      return formatted.substring(0, 6);
    }
    return formatted;
  }
}