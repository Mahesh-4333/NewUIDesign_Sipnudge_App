package com.sipnudge.sipnudge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.text.Html
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors

data class SlotItem(
    val label: String,
    val hour: Int,
    val minute: Int,
    val endHour: Int,
    val endMinute: Int,
    val target: Int
)

class HomeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "HomeWidgetProvider"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private val httpExecutor = Executors.newSingleThreadExecutor()
        private val mainHandler = Handler(Looper.getMainLooper())

        private fun getDefaultSlots(goal: Int): List<SlotItem> {
            val totalGoal = if (goal > 0) goal else 2500
            return listOf(
                SlotItem("Wakeup Time", 7, 0, 9, 0, (totalGoal * 0.20).toInt()),
                SlotItem("Morning Boost", 9, 0, 11, 30, (totalGoal * 0.16).toInt()),
                SlotItem("Lunch Time", 11, 30, 14, 0, (totalGoal * 0.16).toInt()),
                SlotItem("Afternoon Boost", 14, 0, 16, 30, (totalGoal * 0.16).toInt()),
                SlotItem("Evening Refresh", 16, 30, 19, 0, (totalGoal * 0.14).toInt()),
                SlotItem("Dinner Time", 19, 0, 21, 0, (totalGoal * 0.12).toInt()),
                SlotItem("Bedtime", 21, 0, 23, 0, (totalGoal * 0.06).toInt())
            )
        }

        fun updateAllWidgets(context: Context, fetchServer: Boolean = true) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, HomeWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    appWidgetIds.forEach { widgetId ->
                        val views = buildRemoteViews(context, prefs)
                        appWidgetManager.updateAppWidget(widgetId, views)
                    }
                    Log.d(TAG, "Successfully updated ${appWidgetIds.size} widget(s)")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in updateAllWidgets: ${e.message}")
            }

            if (fetchServer) {
                fetchWidgetDataFromServer(context)
            }
        }

        fun fetchWidgetDataFromServer(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val userId = getSafeString(prefs, "user_id", null) ?: return
            if (userId.isEmpty() || userId == "guest_user") return

            val now = Date()
            val cal = Calendar.getInstance()
            cal.time = now
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val startOfToday = cal.time

            cal.set(Calendar.HOUR_OF_DAY, 23)
            cal.set(Calendar.MINUTE, 59)
            cal.set(Calendar.SECOND, 59)
            cal.set(Calendar.MILLISECOND, 999)
            val endOfToday = cal.time

            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val startDateStr = isoFormat.format(startOfToday)
            val endDateStr = isoFormat.format(endOfToday)

            val sdfToday = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val todayStr = sdfToday.format(now)

            httpExecutor.execute {
                try {
                    val encodedStart = URLEncoder.encode(startDateStr, "UTF-8")
                    val encodedEnd = URLEncoder.encode(endDateStr, "UTF-8")
                    val urlString = "https://api.sipnudge.com/api/database/today-widget-data/$userId?startDate=$encodedStart&endDate=$encodedEnd"
                    val url = URL(urlString)
                    val conn = url.openConnection() as HttpURLConnection
                    conn.requestMethod = "GET"
                    conn.connectTimeout = 8000
                    conn.readTimeout = 8000

                    val code = conn.responseCode
                    if (code == 200) {
                        val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                        val json = JSONObject(responseText)
                        if (json.optBoolean("success", false)) {
                            val summary = json.optJSONObject("data")
                            if (summary != null) {
                                val consumed = summary.optDouble("consumed", summary.optInt("consumed", 0).toDouble()).toInt()
                                val target = summary.optDouble("target", summary.optInt("target", 2500).toDouble()).toInt()
                                val coffeeIntake = summary.optInt("coffeeIntake", 0)
                                val waterIntake = summary.optInt("waterIntake", 0)
                                val latestDrinkType = summary.optString("latestDrinkType", "")
                                val latestDrinkAmount = summary.optInt("latestDrinkAmount", 0)
                                val battery = summary.optInt("battery", 0)

                                val editor = prefs.edit()
                                editor.putInt("flutter.current_intake", consumed)
                                editor.putInt("current_intake", consumed)

                                val currentStoredGoal = getSafeInt(prefs, "daily_goal", 0)
                                if (currentStoredGoal <= 0 && target > 0) {
                                    editor.putInt("flutter.daily_goal", target)
                                    editor.putInt("daily_goal", target)
                                }
                                editor.putInt("flutter.coffee_intake", coffeeIntake)
                                editor.putInt("coffee_intake", coffeeIntake)
                                editor.putInt("flutter.water_intake", waterIntake)
                                editor.putInt("water_intake", waterIntake)
                                editor.putString("flutter.latest_drink_type", latestDrinkType)
                                editor.putString("latest_drink_type", latestDrinkType)
                                editor.putInt("flutter.latest_drink_amount", latestDrinkAmount)
                                editor.putInt("latest_drink_amount", latestDrinkAmount)

                                if (battery > 0) {
                                    editor.putInt("flutter.battery", battery)
                                    editor.putInt("battery", battery)
                                }

                                editor.putString("flutter.last_update_date", todayStr)
                                editor.putString("last_update_date", todayStr)
                                editor.apply()

                                mainHandler.post {
                                    val appWidgetManager = AppWidgetManager.getInstance(context)
                                    val componentName = ComponentName(context, HomeWidgetProvider::class.java)
                                    val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                                    if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                                        appWidgetIds.forEach { widgetId ->
                                            val views = buildRemoteViews(context, prefs)
                                            appWidgetManager.updateAppWidget(widgetId, views)
                                        }
                                        Log.d(TAG, "Refreshed ${appWidgetIds.size} widget(s) after server sync")
                                    }
                                }
                            }
                        }
                    }
                    conn.disconnect()
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to fetch widget data from server: ${e.message}")
                }
            }
        }

        private fun formatNumber(number: Int): String {
            return NumberFormat.getNumberInstance(Locale.US).format(number)
        }

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

        private fun getSafeDouble(prefs: SharedPreferences, key: String, default: Double = 0.0): Double {
            return try {
                val all = prefs.all
                val value = all["flutter.$key"] ?: all[key] ?: return default
                when (value) {
                    is Number -> value.toDouble()
                    is String -> value.toDoubleOrNull() ?: default
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

        fun buildRemoteViews(context: Context, widgetData: SharedPreferences): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val now = Date()
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val todayStr = sdf.format(now)

            val lastUpdateDate = getSafeString(widgetData, "last_update_date", "") ?: ""
            val isNewDay = lastUpdateDate != todayStr && lastUpdateDate.isNotEmpty()

            var intake = getSafeInt(widgetData, "current_intake", 0)
            var goal = getSafeInt(widgetData, "daily_goal", 0)
            if (goal <= 0) {
                goal = getSafeInt(widgetData, "water_goal", 2500)
            }
            if (goal <= 0) goal = 2500

            var battery = getSafeInt(widgetData, "battery", 0)
            if (battery <= 0) {
                battery = getSafeInt(widgetData, "bottle_percent", 75)
            }
            if (battery <= 0) battery = 75

            var expectedPercent = getSafeDouble(widgetData, "expected_percent", 0.0)

            var upcomingSlotName = getSafeString(widgetData, "upcoming_slot_name", "Wakeup Time") ?: "Wakeup Time"
            var upcomingSlotTime = getSafeString(widgetData, "upcoming_slot_time", "--:--") ?: "--:--"

            if (isNewDay) {
                intake = 0
                expectedPercent = 0.0
            }

            // Recent added amount indicator within 5 seconds
            var recentAddedAmount: Int? = null
            if (!isNewDay) {
                val recentTime = getSafeDouble(widgetData, "recent_added_time", 0.0)
                if (recentTime > 0) {
                    val elapsed = (System.currentTimeMillis() / 1000.0) - recentTime
                    if (elapsed in 0.0..5.0) {
                        val amt = getSafeInt(widgetData, "recent_added_amount", 0)
                        if (amt > 0) recentAddedAmount = amt
                    }
                }
            }

            // Dynamic slot schedule calculation matching iOS SipnudgeWidget.swift
            val slotsJson = getSafeString(widgetData, "all_slots_json", null)
            var hasDynamicSlots = false
            val parsedSlots = mutableListOf<SlotItem>()

            if (!slotsJson.isNullOrEmpty()) {
                try {
                    val slotsArray = JSONArray(slotsJson)
                    for (i in 0 until slotsArray.length()) {
                        val obj = slotsArray.getJSONObject(i)
                        parsedSlots.add(
                            SlotItem(
                                label = obj.optString("label", "Hydration Slot"),
                                hour = obj.optInt("hour", 0),
                                minute = obj.optInt("minute", 0),
                                endHour = obj.optInt("endHour", 0),
                                endMinute = obj.optInt("endMinute", 0),
                                target = obj.optInt("target", 0)
                            )
                        )
                    }
                } catch (_: Exception) {}
            }

            val slotsList = if (parsedSlots.isNotEmpty()) {
                hasDynamicSlots = true
                parsedSlots
            } else {
                getDefaultSlots(goal)
            }

            if (slotsList.isNotEmpty()) {
                val cal = Calendar.getInstance()
                val nowHour = cal.get(Calendar.HOUR_OF_DAY)
                val nowMinute = cal.get(Calendar.MINUTE)
                val nowTotalMinutes = nowHour * 60 + nowMinute

                // Sort slots by time
                val sortedSlots = slotsList.sortedWith(compareBy({ it.hour * 60 + it.minute }))

                // Find first slot that starts after now
                val upcomingSlot = sortedSlots.firstOrNull { (it.hour * 60 + it.minute) > nowTotalMinutes }
                    ?: sortedSlots.first()

                upcomingSlotName = upcomingSlot.label

                // Format time string
                val hour12 = if (upcomingSlot.hour % 12 == 0) 12 else upcomingSlot.hour % 12
                val period = if (upcomingSlot.hour < 12) "AM" else "PM"
                val minStr = String.format(Locale.US, "%02d", upcomingSlot.minute)
                upcomingSlotTime = "$hour12:$minStr $period"

                // Calculate cumulative expected targets at current date/time (Slot-by-slot)
                val totalSlotsTarget = sortedSlots.sumOf { it.target.toDouble() }
                var expectedCumulative = 0.0
                for (slot in sortedSlots) {
                    val startMin = slot.hour * 60 + slot.minute
                    val endMin = slot.endHour * 60 + slot.endMinute

                    if (nowTotalMinutes >= endMin) {
                        // Slot has passed -> add full slot target
                        expectedCumulative += slot.target.toDouble()
                    } else if (nowTotalMinutes in startMin until endMin) {
                        // Currently active slot -> progress smoothly during its active window
                        val duration = endMin - startMin
                        if (duration > 0) {
                            val elapsed = nowTotalMinutes - startMin
                            expectedCumulative += slot.target.toDouble() * (elapsed.toDouble() / duration.toDouble())
                        }
                        break
                    } else {
                        // Next slots haven't started yet
                        break
                    }
                }

                val baseTotal = if (totalSlotsTarget > 0) totalSlotsTarget else goal.toDouble()
                expectedPercent = if (baseTotal > 0) Math.min(Math.max((expectedCumulative / baseTotal) * 100.0, 0.0), 100.0) else 0.0
            }

            if (!hasDynamicSlots) {
                if (!isNewDay) {
                    val fallbackPercent = getSafeDouble(widgetData, "expected_percent", -1.0)
                    if (fallbackPercent >= 0.0) {
                        expectedPercent = fallbackPercent
                    }
                } else {
                    expectedPercent = 0.0
                }
            }

            val progress = if (goal > 0) Math.min(intake.toDouble() / goal.toDouble(), 1.0) else 0.0
            val isCurrentlyOnTrack = intake > 0 && intake >= (goal * expectedPercent / 100.0)

            val headingText = if (intake <= 0) {
                "Time to drink!"
            } else if (isCurrentlyOnTrack) {
                "You’re on track"
            } else {
                "You’re not on track"
            }

            val headingColor = if (isCurrentlyOnTrack) {
                Color.parseColor("#172645")
            } else {
                Color.parseColor("#EF4444")
            }

            val percentageString = "${(progress * 100).toInt()}%"

            // Render high-res gauge bitmap with Urbanist font and yellow schedule target
            val gaugeBitmap = WidgetRingRenderer.renderGauge(
                progress = progress,
                expectedPercent = expectedPercent,
                percentageString = percentageString,
                recentAddedAmount = recentAddedAmount,
                context = context
            )
            views.setImageViewBitmap(R.id.widget_gauge_image, gaugeBitmap)

            // Text & Numbers (Bold navy intake + medium slate goal)
            val intakeHtml = "<b><font color='#172645'>${formatNumber(intake)}</font></b> <font color='#55687F'>/ ${formatNumber(goal)} ml</font>"
            views.setTextViewText(R.id.widget_intake_text, Html.fromHtml(intakeHtml, Html.FROM_HTML_MODE_LEGACY))
            views.setTextViewText(R.id.widget_heading_text, headingText)
            views.setTextColor(R.id.widget_heading_text, headingColor)

            // Battery (Dynamic color based on percentage: <20% Red, 20-49% Orange, >=50% Green)
            val batteryIconBitmap = WidgetRingRenderer.renderBatteryIcon(battery)
            val batteryBarBitmap = WidgetRingRenderer.renderBatteryBar(battery)
            views.setImageViewBitmap(R.id.widget_battery_icon, batteryIconBitmap)
            views.setImageViewBitmap(R.id.widget_battery_bar, batteryBarBitmap)
            views.setTextViewText(R.id.widget_battery_text, "$battery%")

            // Next Sip & Only Left
            views.setTextViewText(R.id.widget_next_sip_time, upcomingSlotTime)
            views.setTextViewText(R.id.widget_only_left_text, "${formatNumber(Math.max(0, goal - intake))} ml")

            // 1-Tap Quick Action: Coffee (+150 ml)
            val coffeeIntent = Intent(context, WidgetQuickLogReceiver::class.java).apply {
                action = WidgetQuickLogReceiver.ACTION_QUICK_LOG
                putExtra(WidgetQuickLogReceiver.EXTRA_DRINK_TYPE, "Coffee")
                putExtra(WidgetQuickLogReceiver.EXTRA_AMOUNT, 150)
            }
            val coffeePendingIntent = PendingIntent.getBroadcast(
                context,
                150,
                coffeeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_quick_coffee, coffeePendingIntent)

            // 1-Tap Quick Action: Water (+250 ml)
            val waterIntent = Intent(context, WidgetQuickLogReceiver::class.java).apply {
                action = WidgetQuickLogReceiver.ACTION_QUICK_LOG
                putExtra(WidgetQuickLogReceiver.EXTRA_DRINK_TYPE, "Water")
                putExtra(WidgetQuickLogReceiver.EXTRA_AMOUNT, 250)
            }
            val waterPendingIntent = PendingIntent.getBroadcast(
                context,
                250,
                waterIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_quick_water, waterPendingIntent)

            // Widget Body Tap -> Open App
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent(context, MainActivity::class.java)
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val appPendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, appPendingIntent)

            return views
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        appWidgetIds.forEach { widgetId ->
            val views = buildRemoteViews(context, prefs)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        fetchWidgetDataFromServer(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        updateAllWidgets(context)
    }
}
