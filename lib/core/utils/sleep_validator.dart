import 'date_utils.dart';

class SleepOpportunityResult {
  final int totalMinutes;
  final double hours;
  final bool isInsufficient;
  final String? advisoryMessage;

  const SleepOpportunityResult({
    required this.totalMinutes,
    required this.hours,
    required this.isInsufficient,
    this.advisoryMessage,
  });
}

class SleepValidator {
  /// Evaluates the rest opportunity between bedtime and waking time.
  /// Bedtime e.g., 01:00 (1:00 AM) and waking time e.g., 06:00 (6:00 AM) leaves 5.0 hours.
  /// If the window is <= 5.0 hours (300 minutes), generates an unobtrusive health advisory
  /// without coercion, moral judgment, or blocking the user from saving (FR-ON-05, FR-HL-02).
  static SleepOpportunityResult evaluateWindow({
    required int bedHour,
    required int bedMinute,
    required int wakeHour,
    required int wakeMinute,
  }) {
    final int minutes = AppDateUtils.calculateDurationMinutes(
      startHour: bedHour,
      startMinute: bedMinute,
      endHour: wakeHour,
      endMinute: wakeMinute,
    );

    final double hours = minutes / 60.0;
    final bool isInsufficient = minutes <= 300; // <= 5 hours

    String? advisory;
    if (isInsufficient) {
      advisory = 'Rest Advisory: A ${hours.toStringAsFixed(1)}-hour sleep window '
          'leaves limited physical and cognitive recovery time. '
          'Consider an earlier bedtime, protected nap, or alternating late devotional sessions. '
          'You may save this schedule, but please protect your health.';
    }

    return SleepOpportunityResult(
      totalMinutes: minutes,
      hours: hours,
      isInsufficient: isInsufficient,
      advisoryMessage: advisory,
    );
  }
}
