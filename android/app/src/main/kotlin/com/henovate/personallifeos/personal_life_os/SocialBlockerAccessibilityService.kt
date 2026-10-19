package com.henovate.personallifeos.personal_life_os

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class SocialBlockerAccessibilityService : AccessibilityService() {

    companion object {
        var isShieldActive: Boolean = false
        var emergencyOverrideUntilMs: Long = 0L
        var blockedPackages: MutableSet<String> = mutableSetOf(
            "com.instagram.android",
            "com.twitter.android",
            "com.zhiliaoapp.musically", // TikTok
            "com.ss.android.ugc.trill",
            "com.facebook.katana",
            "com.snapchat.android",
            "com.reddit.frontpage"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isShieldActive) return
        // If an emergency override is currently active, bypass blocking
        if (System.currentTimeMillis() < emergencyOverrideUntilMs) return
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (blockedPackages.contains(packageName)) {
            // Force return to home screen and display focus notice
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)

            Toast.makeText(
                this,
                "Personal Life OS: App locked by Focus Governance.",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onInterrupt() {}
}
