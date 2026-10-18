import 'package:intl/intl.dart';

class MoneyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
    locale: 'en_NG',
  );

  static final NumberFormat _compactNairaFormat = NumberFormat.compactCurrency(
    symbol: '₦',
    locale: 'en_NG',
  );

  /// Formats integer minor units (kobo) into a formatted string (e.g. 150000 -> ₦1,500.00).
  static String formatKobo(int kobo, {bool showDecimals = true}) {
    final double value = kobo / 100.0;
    if (!showDecimals && kobo % 100 == 0) {
      return NumberFormat.currency(
        symbol: '₦',
        decimalDigits: 0,
        locale: 'en_NG',
      ).format(value);
    }
    return _nairaFormat.format(value);
  }

  /// Compact representation for dashboard cards (e.g., ₦1.5M).
  static String formatCompact(int kobo) {
    final double value = kobo / 100.0;
    return _compactNairaFormat.format(value);
  }

  /// Parses a user-entered text string (e.g., "1500", "1,500.50", "₦2,000") into integer kobo.
  /// Throws FormatException if the input is malformed or negative (unless allowNegative is true).
  static int parseToKobo(String input, {bool allowNegative = false}) {
    String sanitized = input
        .replaceAll('₦', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    if (sanitized.isEmpty) {
      throw const FormatException('Amount cannot be empty');
    }

    final double parsed = double.tryParse(sanitized) ??
        (throw FormatException('Invalid currency number: $input'));

    if (parsed.isNaN || parsed.isInfinite) {
      throw const FormatException('Amount must be a finite number');
    }

    if (!allowNegative && parsed < 0) {
      throw const FormatException('Amount cannot be negative');
    }

    // Multiply by 100 and round to nearest integer to avoid float inaccuracies
    return (parsed * 100).round();
  }

  /// Validates whether a text input string is a valid positive money amount.
  static bool isValidAmount(String input) {
    try {
      final kobo = parseToKobo(input);
      return kobo > 0;
    } catch (_) {
      return false;
    }
  }
}
