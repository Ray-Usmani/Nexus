package com.example.budget_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ExpenseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val todayTotal = widgetData.getFloat("today_total", 0f)
        val safeToSpend = widgetData.getFloat("safe_to_spend", 0f)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.expense_widget).apply {
                setTextViewText(R.id.today_total, "Today: ₹${todayTotal.toInt()}")
                setTextViewText(R.id.safe_to_spend, "Safe: ₹${safeToSpend.toInt()}/day")
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
