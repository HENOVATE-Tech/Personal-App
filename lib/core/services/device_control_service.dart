import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceControlService {
  static final DeviceControlService instance = DeviceControlService._internal();
  DeviceControlService._internal();

  static const _channel = MethodChannel('com.henovate.personallifeos/device_control');

  static const _prefOverrideExpiryKey = 'plos_emergency_override_expiry';
  static const _prefOverrideReasonKey = 'plos_emergency_override_reason';
  static const _prefBlockedPackagesKey = 'plos_blocked_packages';
  static const _prefGovernedAppsKey = 'plos_governed_apps';
  static const _prefShieldEnabledKey = 'plos_shield_enabled';

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefShieldEnabledKey, enable);
      final res = await _channel.invokeMethod<bool>('setSocialMediaShield', {'enable': enable});
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Checks if social media shield is enabled
  Future<bool> isSocialMediaShieldEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefShieldEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Sets the active list of blocked application package names
  Future<bool> setBlockedPackages(List<String> packages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefBlockedPackagesKey, packages);
      final res = await _channel.invokeMethod<bool>('setBlockedPackages', {'packages': packages});
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Gets the active list of blocked application package names
  Future<List<String>> getBlockedPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefBlockedPackagesKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Saves custom governed apps map
  Future<void> saveGovernedApps(Map<String, String> apps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefGovernedAppsKey, jsonEncode(apps));
    } catch (_) {}
  }

  /// Gets custom governed apps map
  Future<Map<String, String>> getGovernedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefGovernedAppsKey);
      if (str != null && str.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(str);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {}
    return {};
  }

  /// Activates an emergency focus override for a specified duration in minutes
  Future<bool> requestEmergencyOverride({int durationMinutes = 15, String reason = ''}) async {
    try {
      final expiry = DateTime.now().add(Duration(minutes: durationMinutes)).millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefOverrideExpiryKey, expiry);
      if (reason.isNotEmpty) {
        await prefs.setString(_prefOverrideReasonKey, reason);
      }
      final res = await _channel.invokeMethod<bool>('requestEmergencyOverride', {'durationMinutes': durationMinutes});
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Cancels active emergency override
  Future<void> cancelEmergencyOverride() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefOverrideExpiryKey);
      await prefs.remove(_prefOverrideReasonKey);
    } catch (_) {}
  }

  /// Gets remaining emergency override seconds (0 if inactive)
  Future<int> getEmergencyOverrideRemainingSeconds() async {
    try {
      final res = await _channel.invokeMethod<int>('getEmergencyOverrideRemainingSeconds');
      if (res != null && res > 0) return res;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = prefs.getInt(_prefOverrideExpiryKey);
      if (expiry != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final remainingMs = expiry - now;
        if (remainingMs > 0) {
          return (remainingMs / 1000).ceil();
        } else {
          await prefs.remove(_prefOverrideExpiryKey);
          await prefs.remove(_prefOverrideReasonKey);
        }
      }
    } catch (_) {}

    return 0;
  }

  /// Gets the reason for the active emergency override
  Future<String> getEmergencyOverrideReason() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefOverrideReasonKey) ?? '';
    } catch (_) {
      return '';
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
