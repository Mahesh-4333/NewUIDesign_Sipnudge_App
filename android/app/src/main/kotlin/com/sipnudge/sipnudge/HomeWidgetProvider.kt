package com.sipnudge.sipnudge

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val lastUpdateDate = widgetData.getString("last_update_date", "")
                val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
                val todayStr = sdf.format(java.util.Date())
                val intake = if (lastUpdateDate == todayStr) widgetData.getInt("current_intake", 0) else 0
                val goal = widgetData.getInt("daily_goal", 2000)
                
                setTextViewText(R.id.widget_intake, "$intake ml / $goal ml")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
