class RecurrenceEngine {
  /// Finds the last Friday, Saturday, and Sunday of a given month and year.
  /// Handles leap years, February lengths, and short months properly.
  /// Used for monthly 3-day fasting templates (FR-SP-04, BR-03).
  static List<DateTime> getLastWeekendOfMonth(int year, int month) {
    // Determine the last day of this month
    final DateTime firstOfNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final DateTime lastDayOfMonth = firstOfNextMonth.subtract(const Duration(days: 1));

    // Find the last Sunday of the month
    DateTime lastSunday = lastDayOfMonth;
    while (lastSunday.weekday != DateTime.sunday) {
      lastSunday = lastSunday.subtract(const Duration(days: 1));
    }

    final DateTime lastSaturday = lastSunday.subtract(const Duration(days: 1));
    final DateTime lastFriday = lastSunday.subtract(const Duration(days: 2));

    return [
      DateTime(lastFriday.year, lastFriday.month, lastFriday.day),
      DateTime(lastSaturday.year, lastSaturday.month, lastSaturday.day),
      DateTime(lastSunday.year, lastSunday.month, lastSunday.day),
    ];
  }

  /// Calculates recurring fasting dates for a month, resolving the overlap between
  /// weekly Friday fasting and the monthly 3-day last Friday-Sunday fast.
  /// Implements BR-03: The Friday inside the monthly 3-day period must produce
  /// exactly three distinct dates for the weekend, and that Friday is counted once
  /// against regular Friday fasting without scheduling duplicate reminders.
  static List<DateTime> getFastingScheduleForMonth({
    required int year,
    required int month,
    bool includeMondayFasts = true,
    bool includeFridayFasts = true,
    bool includeMonthlyThreeDayFast = true,
  }) {
    final Set<String> dateKeySet = {};
    final List<DateTime> results = [];

    void addDate(DateTime dt) {
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      if (!dateKeySet.contains(key)) {
        dateKeySet.add(key);
        results.add(DateTime(dt.year, dt.month, dt.day));
      }
    }

    // 1. Add regular Monday & Friday fasts
    final DateTime firstOfMonth = DateTime(year, month, 1);
    final DateTime firstOfNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final int daysInMonth = firstOfNextMonth.difference(firstOfMonth).inDays;

    for (int day = 1; day <= daysInMonth; day++) {
      final candidate = DateTime(year, month, day);
      if (includeMondayFasts && candidate.weekday == DateTime.monday) {
        addDate(candidate);
      }
      if (includeFridayFasts && candidate.weekday == DateTime.friday) {
        addDate(candidate);
      }
    }

    // 2. Add monthly 3-day fast (last Friday, Saturday, Sunday)
    if (includeMonthlyThreeDayFast) {
      final weekend = getLastWeekendOfMonth(year, month);
      for (final date in weekend) {
        addDate(date); // Deduplicates Friday automatically via Set
      }
    }

    results.sort((a, b) => a.compareTo(b));
    return results;
  }

  /// Clamps or resolves a target day of month (e.g. 31st) to the last valid day if the month is shorter (BR-10).
  static DateTime clampDate(int year, int month, int targetDay) {
    final DateTime firstOfNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final int maxDaysInMonth = firstOfNextMonth.difference(DateTime(year, month, 1)).inDays;

    final int effectiveDay = targetDay > maxDaysInMonth ? maxDaysInMonth : targetDay;
    return DateTime(year, month, effectiveDay);
  }

  /// Checks whether a given date is the last Friday of its month.
  static bool isLastFridayOfMonth(DateTime date) {
    if (date.weekday != DateTime.friday) return false;
    final nextWeek = date.add(const Duration(days: 7));
    return nextWeek.month != date.month;
  }
}
