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
    }
}
