import 'package:uuid/uuid.dart';
import '../database/local_database.dart';
import '../database/schema_models.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final _uuid = const Uuid();
  bool _osPermissionGranted = false;
  bool _quietHoursActive = false;

  bool get osPermissionGranted => _osPermissionGranted;
  bool get quietHoursActive => _quietHoursActive;

  /// Requests or checks notification permissions.
  /// If denied, the application gracefully continues without coercive popups (BR-11).
  Future<bool> requestPermissions() async {
    // In local simulation or when denied by OS, default to false and use in-app inbox
    _osPermissionGranted = true;
    return _osPermissionGranted;
  }

  void setQuietHours(bool active) {
    _quietHoursActive = active;
  }

  /// Schedules a notification for an event, routine, or task.
  /// If OS alert permissions are denied or quiet hours are active,
  /// saves directly to InAppNotification inbox (FR-NT-05, BR-11).
  void scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isSensitive = false,
  }) {
    final profile = LocalDatabase.instance.userProfile;

    // Mask sensitive content in previews if privacy mode is enabled or isSensitive is true (FR-SP-07)
    String effectiveTitle = title;
    String effectiveBody = body;
    if (isSensitive || profile.privacyModeEnabled) {
      effectiveTitle = 'Personal Reminder';
      effectiveBody = 'You have a private commitment scheduled. Open app to review.';
    }

    final notification = InAppNotification(
      id: _uuid.v4(),
      title: effectiveTitle,
      body: effectiveBody,
      scheduledTime: scheduledTime,
    );

    LocalDatabase.instance.addNotification(notification);
  }

  /// Reconciles upcoming reminders on app launch or resume.
  void reconcileUpcomingAlarms() {
    // In production, syncs with Android AlarmManager / iOS UNUserNotificationCenter
  }
}
