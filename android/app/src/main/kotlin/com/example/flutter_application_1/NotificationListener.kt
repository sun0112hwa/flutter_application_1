package com.example.flutter_application_1

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (sbn.packageName != "com.kakao.talk") {
            return
        }

        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: extras.getString("android.title.big") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: extras.getCharSequence("android.text.big")?.toString() ?: ""

        val intent = Intent("com.example.flutter_application_1.NOTIFICATION_POSTED")
        intent.putExtra("package", sbn.packageName)
        intent.putExtra("title", title)
        intent.putExtra("text", text)
        sendBroadcast(intent)
    }
}
