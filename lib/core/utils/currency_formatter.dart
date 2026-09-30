import 'package:intl/intl.dart';

/// Central currency and formatting utility.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactSimpleCurrency(
    name: 'USD',
  );

  /// Formats integer minor units (e.g. 1050 cents -> "$10.50").
  static String formatMinor(int amountMinor, {bool includeSign = false}) {
    final absAmount = (amountMinor.abs()) / 100.0;
    final formatted = _currencyFormat.format(absAmount);

    if (amountMinor < 0) {
      return '-$formatted';
    } else if (amountMinor > 0 && includeSign) {
      return '+$formatted';
    }
    return formatted;
  }

  /// Compact formatting for charts and badges (e.g. $1.2K).
  static String formatCompact(int amountMinor) {
    return _compactCurrencyFormat.format(amountMinor / 100.0);
  }

  /// Converts human decimal string into minor units (e.g. "12.50" -> 1250).
  static int parseToMinor(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return 0;
    final parsed = double.tryParse(cleaned) ?? 0.0;
    return (parsed * 100).round();
  }
}
