package com.example.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen widget that shows the top 4 active tasks, sorted by due date.
 * Data is written by Flutter via HomeWidget.saveWidgetData().
 */
class TrackerTaskWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = HomeWidgetPlugin.getData(context)
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context, data))
        }
    }

    private fun buildViews(
        context: Context,
        data: android.content.SharedPreferences,
    ): RemoteViews = RemoteViews(context.packageName, R.layout.tracker_task_widget).apply {

        // Tap root → open app
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            val pi = PendingIntent.getActivity(
                context, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, pi)
        }

        setTextViewText(R.id.last_updated, data.getString("last_updated", "") ?: "")

        // ── Task rows ────────────────────────────────────────────────────────
        data class Slot(val row: Int, val title: Int, val due: Int, val key: String)

        val slots = listOf(
            Slot(R.id.task_row_1, R.id.task_title_1, R.id.task_due_1, "task_1"),
            Slot(R.id.task_row_2, R.id.task_title_2, R.id.task_due_2, "task_2"),
            Slot(R.id.task_row_3, R.id.task_title_3, R.id.task_due_3, "task_3"),
            Slot(R.id.task_row_4, R.id.task_title_4, R.id.task_due_4, "task_4"),
        )

        var shown = 0
        for (slot in slots) {
            if (data.getBoolean("${slot.key}_visible", false)) {
                shown++
                setViewVisibility(slot.row, View.VISIBLE)
                setTextViewText(slot.title, data.getString("${slot.key}_title", "") ?: "")
                val due = data.getString("${slot.key}_due", "") ?: ""
                val overdue = data.getBoolean("${slot.key}_overdue", false)
                setTextViewText(slot.due, due)
                setTextColor(slot.due, dueColor(due, overdue))
            } else {
                setViewVisibility(slot.row, View.GONE)
            }
        }

        setViewVisibility(R.id.no_tasks_text, if (shown == 0) View.VISIBLE else View.GONE)
    }

    private fun dueColor(due: String, overdue: Boolean): Int = when {
        overdue || due == "Overdue"  -> 0xFFEF4444.toInt()
        due == "Today"               -> 0xFF818CF8.toInt()
        due == "Tomorrow"            -> 0xFFFBBF24.toInt()
        else                         -> 0xFF888888.toInt()
    }
}
