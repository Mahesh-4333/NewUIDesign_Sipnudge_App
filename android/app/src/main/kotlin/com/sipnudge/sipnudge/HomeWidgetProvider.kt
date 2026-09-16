package com.sipnudge.sipnudge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.text.Html
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class HomeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "HomeWidgetProvider"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        fun updateAllWidgets(context: Context) {
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
            var goal = getSafeInt(widgetData, "daily_goal", 2500)
            if (goal <= 0) goal = 2500

            var battery = getSafeInt(widgetData, "battery", 75)
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

            // Dynamic slot schedule calculation from JSON if available
            val slotsJson = getSafeString(widgetData, "all_slots_json", null)

            if (!slotsJson.isNullOrEmpty()) {
                try {
                    val slotsArray = JSONArray(slotsJson)
                    if (slotsArray.length() > 0) {
                        val cal = Calendar.getInstance()
                        val nowMinutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)

                        var foundSlot: JSONObject? = null
                        var expectedCumulative = 0.0
                        var totalTarget = 0.0

                        for (i in 0 until slotsArray.length()) {
                            val slot = slotsArray.getJSONObject(i)
                            val startHour = slot.optInt("hour", 0)
                            val startMin = slot.optInt("minute", 0)
                            val endHour = slot.optInt("endHour", startHour + 2)
                            val endMin = slot.optInt("endMinute", startMin)
                            val slotTarget = slot.optInt("target", goal / slotsArray.length())

                            val startTotal = startHour * 60 + startMin
                            val endTotal = endHour * 60 + endMin
                            totalTarget += slotTarget

                            if (nowMinutes >= endTotal) {
                                expectedCumulative += slotTarget
                            } else if (nowMinutes in startTotal until endTotal) {
                                val duration = endTotal - startTotal
                                if (duration > 0) {
                                    val elapsed = nowMinutes - startTotal
                                    expectedCumulative += slotTarget * (elapsed.toDouble() / duration.toDouble())
                                }
                            }

                            if (foundSlot == null && startTotal > nowMinutes) {
                                foundSlot = slot
                            }
                        }

                        val nextSlot = foundSlot ?: slotsArray.getJSONObject(0)
                        upcomingSlotName = nextSlot.optString("label", "Upcoming Sip")

                        val nHour = nextSlot.optInt("hour", 8)
                        val nMin = nextSlot.optInt("minute", 0)
                        val h12 = if (nHour % 12 == 0) 12 else nHour % 12
                        val period = if (nHour < 12) "AM" else "PM"
                        upcomingSlotTime = String.format(Locale.US, "%02d:%02d %s", h12, nMin, period)

                        val baseTotal = if (totalTarget > 0) totalTarget else goal.toDouble()
                        expectedPercent = if (baseTotal > 0) Math.min(Math.max((expectedCumulative / baseTotal) * 100.0, 0.0), 100.0) else 0.0
                    }
                } catch (_: Exception) {}
            }

            if (upcomingSlotTime == "--:--" || upcomingSlotTime.isEmpty()) {
                val cal = Calendar.getInstance()
                val nextHour = (cal.get(Calendar.HOUR_OF_DAY) + 1) % 24
                val h12 = if (nextHour % 12 == 0) 12 else nextHour % 12
                val period = if (nextHour < 12) "AM" else "PM"
                upcomingSlotTime = String.format(Locale.US, "%d:00 %s", h12, period)
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

            // Render high-res gauge bitmap
            val gaugeBitmap = WidgetRingRenderer.renderGauge(
                progress = progress,
                expectedPercent = expectedPercent,
                percentageString = percentageString,
                recentAddedAmount = recentAddedAmount
            )
            views.setImageViewBitmap(R.id.widget_gauge_image, gaugeBitmap)

            // Text & Numbers (Bold navy intake + medium slate goal)
            val intakeHtml = "<b><font color='#172645'>${formatNumber(intake)}</font></b> <font color='#55687F'>/ ${formatNumber(goal)} ml</font>"
            views.setTextViewText(R.id.widget_intake_text, Html.fromHtml(intakeHtml, Html.FROM_HTML_MODE_LEGACY))
            views.setTextViewText(R.id.widget_heading_text, headingText)
            views.setTextColor(R.id.widget_heading_text, headingColor)

            // Battery
            views.setTextViewText(R.id.widget_battery_text, "$battery%")
            views.setProgressBar(R.id.widget_battery_bar, 100, Math.min(battery, 100), false)

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
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        updateAllWidgets(context)
    }
}
