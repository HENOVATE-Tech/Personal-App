import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/utils/date_utils.dart';
import 'package:personal_life_os/core/utils/recurrence_engine.dart';

void main() {
  group('Recurrence Engine & Calendar Constraints (CAL-101..116, BR-03, BR-07, BR-10)', () {
    test('BR-03: Fasting deduplication — Monthly 3-day fast counts Friday once against regular Friday fast', () {
      // October 2026:
      // Oct 2 (Fri), Oct 9 (Fri), Oct 16 (Fri), Oct 23 (Fri), Oct 30 (Fri).
      // Last weekend of Oct 2026: Oct 30 (Fri), Oct 31 (Sat), Nov 1 (Sun).
      // The last Friday (Oct 30) belongs both to weekly Friday fasting and monthly 3-day fast.
      final schedule = RecurrenceEngine.getFastingScheduleForMonth(
        year: 2026,
        month: 10,
        includeMondayFasts: true,
        includeFridayFasts: true,
        includeMonthlyThreeDayFast: true,
      );

      // Verify no duplicate DateTimes exist for October 30
      final oct30Occurrences = schedule.where((d) => d.year == 2026 && d.month == 10 && d.day == 30).toList();
      expect(oct30Occurrences.length, 1, reason: 'Friday October 30 must only appear once in fasting schedule');

      // Verify all dates in list are unique
      final distinctKeys = schedule.map((d) => '${d.year}-${d.month}-${d.day}').toSet();
      expect(distinctKeys.length, schedule.length);
    });

    test('BR-03: Last weekend of month produces 3 distinct dates (Fri, Sat, Sun)', () {
      final weekend = RecurrenceEngine.getLastWeekendOfMonth(2026, 10);
      expect(weekend.length, 3);
      expect(weekend[0].weekday, DateTime.friday);
      expect(weekend[1].weekday, DateTime.saturday);
      expect(weekend[2].weekday, DateTime.sunday);
      expect(weekend[0].isBefore(weekend[1]), isTrue);
      expect(weekend[1].isBefore(weekend[2]), isTrue);
    });

    test('BR-07: Cross-midnight duration — 23:00 to 01:00 computes positive 120 minutes', () {
      final duration = AppDateUtils.calculateDurationMinutes(
        startHour: 23,
        startMinute: 0,
        endHour: 1,
        endMinute: 0,
      );

      expect(duration, 120, reason: 'Cross-midnight event must compute 120 minutes, never negative duration');
    });

    test('BR-07: Standard daytime duration — 06:00 to 08:30 computes positive 150 minutes', () {
      final duration = AppDateUtils.calculateDurationMinutes(
        startHour: 6,
        startMinute: 0,
        endHour: 8,
        endMinute: 30,
      );

      expect(duration, 150);
    });

    test('BR-10: Month clamp policy — February 31 clamps to Feb 28 on non-leap year', () {
      final clampedNonLeap = RecurrenceEngine.clampDate(2025, 2, 31);
      expect(clampedNonLeap.day, 28);
      expect(clampedNonLeap.month, 2);

      // Leap year 2024
      final clampedLeap = RecurrenceEngine.clampDate(2024, 2, 31);
      expect(clampedLeap.day, 29);
      expect(clampedLeap.month, 2);
    });
  });
}
