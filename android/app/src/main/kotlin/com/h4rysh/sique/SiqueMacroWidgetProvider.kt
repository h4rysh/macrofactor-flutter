package com.h4rysh.sique

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class SiqueMacroWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val ownedIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, SiqueMacroWidgetProvider::class.java)
        ).toSet()
        val validIds = appWidgetIds.filter { ownedIds.contains(it) }.toIntArray()
        if (validIds.isNotEmpty()) {
            updateAllWidgets(context, appWidgetManager, validIds)
        }
    }

    companion object {
        private const val PREFS_NAME = "sique_macro_widget_prefs"

        fun saveAndRefresh(
            context: Context,
            caloriesRemaining: Int,
            proteinRemaining: Int,
            carbsRemaining: Int,
            fatRemaining: Int
        ) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
                .putInt("kcal", caloriesRemaining)
                .putInt("p", proteinRemaining)
                .putInt("c", carbsRemaining)
                .putInt("f", fatRemaining)
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, SiqueMacroWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                updateAllWidgets(context, manager, ids)
            }
        }

        private fun updateAllWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val kcal = prefs.getInt("kcal", 2000)
            val p = prefs.getInt("p", 150)
            val c = prefs.getInt("c", 200)
            val f = prefs.getInt("f", 65)

            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.sique_macro_widget)
                views.setTextViewText(R.id.widget_calories, "$kcal kcal")
                views.setTextViewText(R.id.widget_macros, "P ${p}g · C ${c}g · F ${f}g")
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }
}
