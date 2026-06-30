package com.example.flutter_application_1

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationChannel = "com.example.flutter_application_1/notification_events"
    private val methodChannel = "com.example.flutter_application_1/notification_methods"
    private var eventSink: EventChannel.EventSink? = null

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != "com.example.flutter_application_1.NOTIFICATION_POSTED") return
            val extras = intent.extras ?: return
            val payload = mapOf(
                "package" to extras.getString("package", ""),
                "title" to extras.getString("title", ""),
                "text" to extras.getString("text", "")
            )
            eventSink?.success(payload)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver(receiver, IntentFilter("com.example.flutter_application_1.NOTIFICATION_POSTED"))
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterReceiver(receiver)
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationAccessSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                }
                "isNotificationAccessGranted" -> {
                    val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    val packageName = applicationContext.packageName
                    result.success(enabledListeners?.contains(packageName) == true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
