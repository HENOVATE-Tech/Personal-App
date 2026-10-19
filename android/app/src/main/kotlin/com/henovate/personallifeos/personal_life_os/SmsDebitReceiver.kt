package com.henovate.personallifeos.personal_life_os

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import java.util.concurrent.CopyOnWriteArrayList

class SmsDebitReceiver : BroadcastReceiver() {
    companion object {
        val pendingReceivedAlerts = CopyOnWriteArrayList<Map<String, Any>>()
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            val sender = messages[0].displayOriginatingAddress ?: "Bank"
            val sb = java.lang.StringBuilder()
            for (msg in messages) {
                sb.append(msg.displayMessageBody ?: "")
            }
            val body = sb.toString()
            val timestamp = messages[0].timestampMillis

            val alertMap = HashMap<String, Any>()
            alertMap["sender"] = sender
            alertMap["body"] = body
            alertMap["date"] = timestamp

            pendingReceivedAlerts.add(alertMap)
        } catch (_: Exception) {
            // Graceful non-blocking
        }
    }
}
