package com.sipnudge.sipnudge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors

class WidgetQuickLogReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_QUICK_LOG = "com.sipnudge.sipnudge.ACTION_QUICK_LOG"
        const val EXTRA_DRINK_TYPE = "extra_drink_type"
        const val EXTRA_AMOUNT = "extra_amount"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private val executor = Executors.newSingleThreadExecutor()

        private fun getSafeInt(prefs: SharedPreferences, key: String, default: Int = 0): Int {
            return try {
                val all = prefs.all
                val value = all["flutter.$key"] ?: all[key] ?: return default
                when (value) {
                    is Number -> value.toInt()
                    is String -> value.toDoubleOrNull()?.toInt() ?: default
                    else -> default
                }
            } catch (_: Exception) {
                default
            }
        }

        private fun getSafeString(prefs: SharedPreferences, key: String, default: String? = null): String? {
            return try {
                val all = prefs.all
                val value = all["flutter.$key"] ?: all[key] ?: return default
                value.toString()
            } catch (_: Exception) {
                default
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_QUICK_LOG) return

        val drinkType = intent.getStringExtra(EXTRA_DRINK_TYPE) ?: "Water"
        val amount = intent.getIntExtra(EXTRA_AMOUNT, 250)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val todayStr = sdf.format(Date())

        val lastUpdateDate = getSafeString(prefs, "last_update_date", "") ?: ""

        var currentIntake = getSafeInt(prefs, "current_intake", 0)
        var currentCoffee = getSafeInt(prefs, "coffee_intake", 0)
        var currentWater = getSafeInt(prefs, "water_intake", 0)

        if (lastUpdateDate != todayStr && lastUpdateDate.isNotEmpty()) {
            currentIntake = 0
            currentCoffee = 0
            currentWater = 0
        }

        val isCoffee = drinkType.equals("coffee", ignoreCase = true)
        val coefficient = if (isCoffee) 0.8 else 1.0
        val effectiveWater = (amount * coefficient).toInt()
        val newIntake = currentIntake + effectiveWater

        val now = Date()
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val utcTimestamp = isoFormat.format(now)

        // Save updated values to SharedPreferences (both flutter. prefix and plain prefix)
        val editor = prefs.edit()
        editor.putInt("flutter.current_intake", newIntake)
        editor.putInt("current_intake", newIntake)

        if (isCoffee) {
            val newCoffee = currentCoffee + amount
            editor.putInt("flutter.coffee_intake", newCoffee)
            editor.putInt("coffee_intake", newCoffee)
        } else {
            val newWater = currentWater + amount
            editor.putInt("flutter.water_intake", newWater)
            editor.putInt("water_intake", newWater)
        }

        editor.putString("flutter.last_update_date", todayStr)
        editor.putString("last_update_date", todayStr)
        editor.putString("flutter.latest_drink_type", drinkType)
        editor.putString("latest_drink_type", drinkType)
        editor.putInt("flutter.latest_drink_amount", amount)
        editor.putInt("latest_drink_amount", amount)

        // Indicator feedback (+250ml)
        editor.putInt("flutter.recent_added_amount", amount)
        editor.putInt("recent_added_amount", amount)
        val timeNowSec = (System.currentTimeMillis() / 1000.0)
        editor.putString("flutter.recent_added_time", timeNowSec.toString())
        editor.putString("recent_added_time", timeNowSec.toString())

        // Save to pending logs JSON for Flutter SQLite sync
        val pendingJsonStr = getSafeString(prefs, "pending_widget_logs_json", "[]") ?: "[]"

        val pendingArray = try {
            JSONArray(pendingJsonStr)
        } catch (_: Exception) {
            JSONArray()
        }

        val logObject = JSONObject().apply {
            put("type", drinkType)
            put("amount", amount)
            put("effective_water", effectiveWater)
            put("timestamp", utcTimestamp)
            put("localDate", todayStr)
        }
        pendingArray.put(logObject)

        // Accumulate pending manual delta for BLE characteristic 000A
        val currentDelta = getSafeInt(prefs, "pending_manual_liquid_delta", 0)
        val newDelta = currentDelta + effectiveWater
        editor.putInt("flutter.pending_manual_liquid_delta", newDelta)
        editor.putInt("pending_manual_liquid_delta", newDelta)

        editor.putString("flutter.pending_widget_logs_json", pendingArray.toString())
        editor.putString("pending_widget_logs_json", pendingArray.toString())
        editor.apply()

        // Immediately try to sync the delta to the bottle via BLE if connected
        BottleBleService.triggerSyncPendingDelta()

        // Immediately update all widgets
        HomeWidgetProvider.updateAllWidgets(context)

        // Auto-clear "+ xxx ml" indicator after 5 seconds
        Handler(Looper.getMainLooper()).postDelayed({
            HomeWidgetProvider.updateAllWidgets(context)
        }, 5100)

        // Asynchronously post to backend server
        val userId = getSafeString(prefs, "user_id", null)

        if (!userId.isNullOrEmpty() && userId != "guest_user") {
            executor.execute {
                try {
                    val url = URL("https://api.sipnudge.com/api/database/create-manual-log-v2")
                    val conn = url.openConnection() as HttpURLConnection
                    conn.requestMethod = "POST"
                    conn.setRequestProperty("Content-Type", "application/json")
                    conn.connectTimeout = 8000
                    conn.readTimeout = 8000
                    conn.doOutput = true

                    val body = JSONObject().apply {
                        put("userId", userId)
                        put("type", drinkType)
                        put("consumed", amount.toDouble())
                        put("timestamp", utcTimestamp)
                        put("localDate", todayStr)
                    }

                    OutputStreamWriter(conn.outputStream).use { writer ->
                        writer.write(body.toString())
                        writer.flush()
                    }

                    val responseCode = conn.responseCode
                    Log.d("WidgetQuickLog", "POST manual log response: $responseCode")

                    if (responseCode == 200 || responseCode == 201) {
                        try {
                            val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                            val json = JSONObject(responseText)
                            if (json.optBoolean("success", false)) {
                                val serverId = json.optString("serverId", null)
                                if (!serverId.isNullOrEmpty()) {
                                    val currPending = getSafeString(prefs, "pending_widget_logs_json", "[]") ?: "[]"
                                    val arr = JSONArray(currPending)
                                    for (i in 0 until arr.length()) {
                                        val item = arr.getJSONObject(i)
                                        if (item.optString("timestamp") == utcTimestamp) {
                                            item.put("server_id", serverId)
                                            break
                                        }
                                    }
                                    prefs.edit()
                                        .putString("flutter.pending_widget_logs_json", arr.toString())
                                        .putString("pending_widget_logs_json", arr.toString())
                                        .apply()
                                }
                            }
                        } catch (_: Exception) {}
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    Log.w("WidgetQuickLog", "Failed to upload manual log in background: ${e.message}")
                }
            }
        }
    }
}
