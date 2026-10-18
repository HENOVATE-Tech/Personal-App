import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/core/utils/sleep_validator.dart';

void main() {
  group('Sleep Window Opportunity & Health Validation (FR-ON-05, FR-HL-02)', () {
    test('FR-ON-05: 1:00 AM bedtime to 6:00 AM waking window evaluates to 5.0 hours and triggers advisory', () {
      final result = SleepValidator.evaluateWindow(
        bedHour: 1,
        bedMinute: 0,
        wakeHour: 6,
        wakeMinute: 0,
      );

      expect(result.totalMinutes, 300);
      expect(result.hours, 5.0);
      expect(result.isInsufficient, isTrue);
      expect(result.advisoryMessage, contains('leaves limited physical and cognitive recovery time'));
    });

    test('FR-ON-05: Healthy 11:00 PM bedtime to 7:00 AM waking evaluates to 8.0 hours without warning', () {
      final result = SleepValidator.evaluateWindow(
        bedHour: 23,
        bedMinute: 0,
        wakeHour: 7,
        wakeMinute: 0,
      );

      expect(result.totalMinutes, 480);
      expect(result.hours, 8.0);
      expect(result.isInsufficient, isFalse);
      expect(result.advisoryMessage, isNull);
    });

    test('FR-ON-05: Cross-midnight short sleep (02:00 to 06:30) evaluates to 4.5 hours with health caution', () {
      final result = SleepValidator.evaluateWindow(
        bedHour: 2,
        bedMinute: 0,
        wakeHour: 6,
        wakeMinute: 30,
      );

      expect(result.totalMinutes, 270);
      expect(result.hours, 4.5);
      expect(result.isInsufficient, isTrue);
      expect(result.advisoryMessage, isNotNull);
    });
  });
}
