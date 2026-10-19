import 'package:flutter/services.dart';

class DeviceControlService {
  static final DeviceControlService instance = DeviceControlService._internal();
  DeviceControlService._internal();

  static const _channel = MethodChannel('com.henovate.personallifeos/device_control');

  /// Prompts the user to grant Device Administrator mode
  Future<bool> requestDeviceAdmin() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestDeviceAdmin');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks if Device Administrator mode is active
  Future<bool> isDeviceAdminActive() async {
    try {
      final res = await _channel.invokeMethod<bool>('isDeviceAdminActive');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Force-locks the phone immediately (requires Device Admin)
  Future<bool> lockPhone() async {
    try {
      final res = await _channel.invokeMethod<bool>('lockPhone');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers a native phone call dialer
  Future<bool> triggerCall(String phoneNumber) async {
    try {
      final res = await _channel.invokeMethod<bool>('triggerCall', {'phoneNumber': phoneNumber});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Plays the loud system alarm ringtone and triggers vibration
  Future<bool> playAlarmRingtone() async {
    try {
      final res = await _channel.invokeMethod<bool>('playAlarmRingtone');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stops the alarm ringtone
  Future<bool> stopAlarmRingtone() async {
    try {
      final res = await _channel.invokeMethod<bool>('stopAlarmRingtone');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enables or disables the deep social media shield override
  Future<bool> setSocialMediaShield(bool enable) async {
    try {
      final res = await _channel.invokeMethod<bool>('setSocialMediaShield', {'enable': enable});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets the active list of blocked application package names
  Future<bool> setBlockedPackages(List<String> packages) async {
    try {
      final res = await _channel.invokeMethod<bool>('setBlockedPackages', {'packages': packages});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Activates an emergency focus override for a specified duration in minutes
  Future<bool> requestEmergencyOverride({int durationMinutes = 15}) async {
    try {
      final res = await _channel.invokeMethod<bool>('requestEmergencyOverride', {'durationMinutes': durationMinutes});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Gets remaining emergency override seconds (0 if inactive)
  Future<int> getEmergencyOverrideRemainingSeconds() async {
    try {
      final res = await _channel.invokeMethod<int>('getEmergencyOverrideRemainingSeconds');
      return res ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Checks if Accessibility Service is enabled for social media blocking
  Future<bool> isAccessibilityActive() async {
    try {
      final res = await _channel.invokeMethod<bool>('isAccessibilityActive');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens system Accessibility settings
  Future<bool> openAccessibilitySettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
