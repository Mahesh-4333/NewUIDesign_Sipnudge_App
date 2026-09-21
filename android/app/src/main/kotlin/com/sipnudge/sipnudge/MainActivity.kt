package com.sipnudge.sipnudge

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val BLE_CHANNEL = "com.sipnudge.sipnudge/ble_service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        BottleBleService.setFlutterForeground(true)

        try {
            BottleBleService.startService(this)
        } catch (_: Exception) {}

        try {
            val intent = Intent(this, TerminateService::class.java)
            startService(intent)
        } catch (_: Exception) {}
    }

    override fun onResume() {
        super.onResume()
        BottleBleService.setFlutterForeground(true)
    }

    override fun onStop() {
        BottleBleService.setFlutterForeground(false)
        super.onStop()
    }

    override fun onDestroy() {
        BottleBleService.setFlutterForeground(false)
        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BottleBleService.setFlutterForeground(true)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBleService" -> {
                    val address = call.argument<String>("deviceAddress")
                    if (!address.isNullOrEmpty()) {
                        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()
                            .putString("flutter.device_mac", address)
                            .putString("device_mac", address)
                            .putString("flutter.last_device_id", address)
                            .putString("last_device_id", address)
                            .apply()
                    }
                    BottleBleService.startService(this, address)
                    HomeWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "stopBleService" -> {
                    BottleBleService.stopService(this)
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
