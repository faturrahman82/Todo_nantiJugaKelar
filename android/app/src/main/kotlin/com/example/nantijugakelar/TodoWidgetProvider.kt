package com.example.nantijugakelar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val tasksList = widgetData.getString("tasks_list", "Semua tugas beres! 🎉")
                val pendingCount = widgetData.getString("pending_tasks_count", "0 Tertunda")

                setTextViewText(R.id.widget_subtitle, pendingCount)
                setTextViewText(R.id.widget_tasks, tasksList)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
