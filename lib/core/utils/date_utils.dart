import 'package:intl/intl.dart';

class AppDateUtils {
  /// Computes the duration in minutes between start and end.
  /// If isCrossMidnight is true or end is earlier in wall-clock time than start,
  /// treats end as belonging to the next calendar date (e.g. 23:00 to 01:00 = 120 minutes).
  /// This implements BR-07: Never silently produce negative duration.
  static int calculateDurationMinutes({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    bool forceCrossMidnight = false,
  }) {
    final int startTotal = startHour * 60 + startMinute;
    int endTotal = endHour * 60 + endMinute;

    if (forceCrossMidnight || endTotal < startTotal) {
      endTotal += 24 * 60; // Next calendar day
    }

    return endTotal - startTotal;
  }

  /// Formats a time of day with configurable 12-hour or 24-hour display.
  static String formatTime(DateTime dateTime, {bool is24Hour = false}) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats a date cleanly (e.g. "Monday, 19 October 2026").
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM y').format(dateTime);
  }

  /// Formats short date (e.g. "19 Oct").
  static String formatShortDate(DateTime dateTime) {
    return DateFormat('d MMM').format(dateTime);
  }

  /// Returns true if two DateTimes represent the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Normalizes a DateTime to midnight (00:00:00.000).
  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Normalizes a DateTime to end of day (23:59:59.999).
  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }
}
