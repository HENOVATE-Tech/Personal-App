package com.henovate.personallifeos.personal_life_os

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.henovate.personallifeos/device_control"
    private var activeRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDeviceAdmin" -> {
                    val comp = ComponentName(this, PolicyAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, comp)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Enables Personal Life OS deep focus lockdown and screen governance.")
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "isDeviceAdminActive" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val comp = ComponentName(this, PolicyAdminReceiver::class.java)
                    result.success(dpm.isAdminActive(comp))
                }

                "lockPhone" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val comp = ComponentName(this, PolicyAdminReceiver::class.java)
                    if (dpm.isAdminActive(comp)) {
                        dpm.lockNow()
                        result.success(true)
                    } else {
                        result.error("NOT_ADMIN", "Device administrator permission not granted", null)
                    }
                }

                "triggerCall" -> {
                    val number = call.argument<String>("phoneNumber") ?: ""
                    val intent = Intent(Intent.ACTION_DIAL).apply {
                        data = Uri.parse("tel:$number")
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "playAlarmRingtone" -> {
                    try {
                        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        activeRingtone?.stop()
                        activeRingtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
                        activeRingtone?.play()

                        // Vibrate
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                            vm.defaultVibrator.vibrate(VibrationEffect.createOneShot(1000, VibrationEffect.DEFAULT_AMPLITUDE))
                        } else {
                            @Suppress("DEPRECATION")
                            val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                            v.vibrate(1000)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RINGTONE_ERROR", e.localizedMessage, null)
                    }
                }

                "stopAlarmRingtone" -> {
                    activeRingtone?.stop()
                    activeRingtone = null
                    result.success(true)
                }

                "setSocialMediaShield" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    SocialBlockerAccessibilityService.isShieldActive = enable
                    result.success(true)
                }

                "setBlockedPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    SocialBlockerAccessibilityService.blockedPackages = packages.toMutableSet()
                    result.success(true)
                }

                "requestEmergencyOverride" -> {
                    val durationMins = call.argument<Int>("durationMinutes") ?: 15
                    SocialBlockerAccessibilityService.emergencyOverrideUntilMs = System.currentTimeMillis() + (durationMins * 60 * 1000L)
                    result.success(true)
                }

                "getEmergencyOverrideRemainingSeconds" -> {
                    val remaining = (SocialBlockerAccessibilityService.emergencyOverrideUntilMs - System.currentTimeMillis()) / 1000L
                    result.success(if (remaining > 0) remaining else 0L)
                }

                "isAccessibilityActive" -> {
                    val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                    val isEnabled = enabledServices != null && enabledServices.contains(packageName)
                    result.success(isEnabled)
                }

                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // --- SMS Bank Ingestion Channel (Credit & Debit) ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.henovate.personallifeos/sms").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestSmsPermissions" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        requestPermissions(
                            arrayOf(
                                android.Manifest.permission.RECEIVE_SMS,
                                android.Manifest.permission.READ_SMS
                            ),
                            1002
                        )
                    }
                    result.success(true)
                }

                "readRecentDebitAlerts" -> {
                    val alertsList = ArrayList<Map<String, Any>>()

                    // 1. Drain any in-memory broadcast alerts captured in background
                    while (!SmsDebitReceiver.pendingReceivedAlerts.isEmpty()) {
                        val alert = SmsDebitReceiver.pendingReceivedAlerts.removeAt(0)
                        alertsList.add(alert)
                    }

                    // 2. Query ContentResolver SMS Inbox if permission granted
                    try {
                        val hasReadSms = checkSelfPermission(android.Manifest.permission.READ_SMS) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        if (hasReadSms) {
                            val cursor = contentResolver.query(
                                Uri.parse("content://sms/inbox"),
                                arrayOf("address", "body", "date"),
                                null,
                                null,
                                "date DESC"
                            )

                            cursor?.use { c ->
                                val addressIdx = c.getColumnIndex("address")
                                val bodyIdx = c.getColumnIndex("body")
                                val dateIdx = c.getColumnIndex("date")

                                var count = 0
                                while (c.moveToNext() && count < 30) {
                                    val msgBody: String = if (bodyIdx >= 0) c.getString(bodyIdx) ?: "" else ""
                                    val contentLower = msgBody.lowercase(java.util.Locale.ROOT)

                                    val isDebitAlert = contentLower.contains("debit") ||
                                            contentLower.contains(" dr ") ||
                                            contentLower.contains("dr:") ||
                                            contentLower.contains("spent") ||
                                            contentLower.contains("paid")

                                    val isCreditAlert = contentLower.contains("credit") ||
                                            contentLower.contains(" cr ") ||
                                            contentLower.contains("cr:") ||
                                            contentLower.contains("received from") ||
                                            contentLower.contains("credited with") ||
                                            contentLower.contains("inward transfer")

                                    if (isDebitAlert || isCreditAlert) {
                                        val senderStr: String = if (addressIdx >= 0) c.getString(addressIdx) ?: "Bank" else "Bank"
                                        val timestampLong: Long = if (dateIdx >= 0) c.getLong(dateIdx) else System.currentTimeMillis()

                                        val map = HashMap<String, Any>()
                                        map["sender"] = senderStr
                                        map["body"] = msgBody
                                        map["date"] = timestampLong
                                        alertsList.add(map)
                                        count++
                                    }
                                }
                            }
                        }
                    } catch (_: Exception) {
                        // Return what was collected
                    }

                    result.success(alertsList)
                }

                else -> result.notImplemented()
            }
        }
    }
}
