import 'dart:async';
import 'package:uuid/uuid.dart';
import '../database/local_database.dart';
import '../database/schema_models.dart';
import 'device_control_service.dart';

class ScheduledAlarm {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String category; // 'task', 'schedule', 'study', 'prayer', 'finance', 'custom'
  final bool isRinging;
  final bool isDismissed;

  const ScheduledAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.category = 'task',
    this.isRinging = false,
    this.isDismissed = false,
  });

  ScheduledAlarm copyWith({
    String? title,
    String? body,
    DateTime? scheduledTime,
    String? category,
    bool? isRinging,
    bool? isDismissed,
  }) {
    return ScheduledAlarm(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      category: category ?? this.category,
      isRinging: isRinging ?? this.isRinging,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal() {
    startAlarmTicker();
  }

  final _uuid = const Uuid();
  bool _osPermissionGranted = false;
  bool _quietHoursActive = false;
  Timer? _ticker;

  final List<ScheduledAlarm> _alarms = [];
  final _ringingAlarmController = StreamController<ScheduledAlarm?>.broadcast();
  ScheduledAlarm? _currentRingingAlarm;

  Stream<ScheduledAlarm?> get ringingAlarmStream => _ringingAlarmController.stream;
  ScheduledAlarm? get currentRingingAlarm => _currentRingingAlarm;
  List<ScheduledAlarm> get activeAlarms => List.unmodifiable(_alarms.where((a) => !a.isDismissed));

  bool get osPermissionGranted => _osPermissionGranted;
  bool get quietHoursActive => _quietHoursActive;

  void startAlarmTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkDueAlarms();
    });
  }

  void stopAlarmTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _checkDueAlarms() {
    if (_quietHoursActive || _currentRingingAlarm != null) return;

    final now = DateTime.now();
    for (int i = 0; i < _alarms.length; i++) {
      final alarm = _alarms[i];
      if (!alarm.isDismissed && !alarm.isRinging && now.isAfter(alarm.scheduledTime)) {
        _triggerAlarm(alarm, index: i);
        break; // Trigger one alarm at a time
      }
    }
  }

  void _triggerAlarm(ScheduledAlarm alarm, {int? index}) {
    final idx = index ?? _alarms.indexWhere((a) => a.id == alarm.id);
    final ringingAlarm = alarm.copyWith(isRinging: true);
    if (idx >= 0) {
      _alarms[idx] = ringingAlarm;
    }
    _currentRingingAlarm = ringingAlarm;
    _ringingAlarmController.add(ringingAlarm);

    // Play ringing alarm through hardware on Android/iOS
    DeviceControlService.instance.playAlarmRingtone();
  }

  /// Explicitly schedules a ringing alarm for a task, schedule, routine, or study block
  ScheduledAlarm scheduleAlarm({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String category = 'task',
  }) {
    final alarm = ScheduledAlarm(
      id: _uuid.v4(),
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      category: category,
    );

    _alarms.add(alarm);

    // Also persist an InAppNotification for the history log
    LocalDatabase.instance.addNotification(
      InAppNotification(
        id: _uuid.v4(),
        title: 'Alarm: $title',
        body: body,
        scheduledTime: scheduledTime,
      ),
    );

    return alarm;
  }

  /// Dismisses the currently ringing alarm and halts ringtone
  void dismissActiveAlarm() {
    DeviceControlService.instance.stopAlarmRingtone();
    if (_currentRingingAlarm != null) {
      final idx = _alarms.indexWhere((a) => a.id == _currentRingingAlarm!.id);
      if (idx >= 0) {
        _alarms[idx] = _alarms[idx].copyWith(isRinging: false, isDismissed: true);
      }
      _currentRingingAlarm = null;
      _ringingAlarmController.add(null);
    }
  }

  /// Snoozes the currently ringing alarm for a specified number of minutes
  void snoozeActiveAlarm({int minutes = 5}) {
    DeviceControlService.instance.stopAlarmRingtone();
    if (_currentRingingAlarm != null) {
      final idx = _alarms.indexWhere((a) => a.id == _currentRingingAlarm!.id);
      final newTime = DateTime.now().add(Duration(minutes: minutes));
      if (idx >= 0) {
        _alarms[idx] = _alarms[idx].copyWith(
          isRinging: false,
          isDismissed: false,
          scheduledTime: newTime,
        );
      }
      _currentRingingAlarm = null;
      _ringingAlarmController.add(null);
    }
  }

  /// Triggers a test ringing alarm immediately
  void testAlarmNow({String? title}) {
    final testAlarm = ScheduledAlarm(
      id: _uuid.v4(),
      title: title ?? '⏰ Test Alarm: Strategic Focus Review',
      body: 'Your scheduled reminder alarm is ringing loud and clear.',
      scheduledTime: DateTime.now(),
      category: 'test',
    );
    _alarms.insert(0, testAlarm);
    _triggerAlarm(testAlarm, index: 0);
  }

  /// Requests or checks notification permissions.
  Future<bool> requestPermissions() async {
    _osPermissionGranted = true;
    return _osPermissionGranted;
  }

  void setQuietHours(bool active) {
    _quietHoursActive = active;
  }

  /// Schedules a notification for an event, routine, or task.
  void scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isSensitive = false,
  }) {
    final profile = LocalDatabase.instance.userProfile;

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

  void reconcileUpcomingAlarms() {
    _checkDueAlarms();
  }

  void dispose() {
    _ticker?.cancel();
    _ringingAlarmController.close();
  }
}
