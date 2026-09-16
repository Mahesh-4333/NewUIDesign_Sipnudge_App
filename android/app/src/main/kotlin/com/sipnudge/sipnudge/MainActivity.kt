package com.sipnudge.sipnudge

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
    private var serviceConnection: ServiceConnection? = null
    private val BLE_CHANNEL = "com.sipnudge.sipnudge/ble_service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val intent = Intent(this, TerminateService::class.java)
        startService(intent)

        serviceConnection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, service: IBinder?) {}
            override fun onServiceDisconnected(name: ComponentName?) {}
        }
        bindService(intent, serviceConnection!!, Context.BIND_AUTO_CREATE)
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceConnection?.let {
            unbindService(it)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBleService" -> {
                    val address = call.argument<String>("deviceAddress")
                    if (!address.isNullOrEmpty()) {
                        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()
                            .putString("flutter.device_mac", address)
                            .putString("device_mac", address)
                            .apply()
                    }
                    HomeWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "stopBleService" -> {
                    result.success(true)
                }
                "updateWidget" -> {
                    HomeWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
