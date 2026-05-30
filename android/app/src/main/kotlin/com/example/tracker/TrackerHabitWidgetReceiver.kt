package com.example.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen widget that shows all habits with today's completion status
 * and current streak. Data is written by Flutter via HomeWidget.saveWidgetData().
 */
class TrackerHabitWidgetReceiver : AppWidgetProvider() {

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
    ): RemoteViews = RemoteViews(context.packageName, R.layout.tracker_habit_widget).apply {

        // Tap root → open app
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            val pi = PendingIntent.getActivity(
                context, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, pi)
        }

        setTextViewText(R.id.last_updated, data.getString("last_updated", "") ?: "")

        // ── Habit rows ────────────────────────────────────────────────────────
        data class Slot(val row: Int, val dot: Int, val name: Int, val streak: Int, val key: String)

        val slots = listOf(
            Slot(R.id.habit_row_1, R.id.habit_dot_1, R.id.habit_name_1, R.id.habit_streak_1, "habit_1"),
            Slot(R.id.habit_row_2, R.id.habit_dot_2, R.id.habit_name_2, R.id.habit_streak_2, "habit_2"),
            Slot(R.id.habit_row_3, R.id.habit_dot_3, R.id.habit_name_3, R.id.habit_streak_3, "habit_3"),
            Slot(R.id.habit_row_4, R.id.habit_dot_4, R.id.habit_name_4, R.id.habit_streak_4, "habit_4"),
            Slot(R.id.habit_row_5, R.id.habit_dot_5, R.id.habit_name_5, R.id.habit_streak_5, "habit_5"),
        )

        var shown = 0
        for (slot in slots) {
            if (data.getBoolean("${slot.key}_visible", false)) {
                shown++
                setViewVisibility(slot.row, View.VISIBLE)

                val streakVal  = data.getInt("${slot.key}_streak", 0)
                val doneToday  = data.getBoolean("${slot.key}_done", false)

                // Dot: green if done today, indigo if has streak, grey otherwise
                val dotColor = when {
                    doneToday  -> 0xFF34D399.toInt()
                    streakVal > 0 -> 0xFF818CF8.toInt()
                    else       -> 0xFF555577.toInt()
                }
                setTextColor(slot.dot, dotColor)

                setTextViewText(slot.name, data.getString("${slot.key}_name", "") ?: "")

                val streakLabel = when {
                    streakVal > 0 -> "🔥 ${streakVal}d"
                    doneToday     -> "✓"
                    else          -> "—"
                }
                setTextViewText(slot.streak, streakLabel)
                setTextColor(
                    slot.streak,
                    if (doneToday || streakVal > 0) 0xFF34D399.toInt() else 0xFF555566.toInt(),
                )
            } else {
                setViewVisibility(slot.row, View.GONE)
            }
        }

        setViewVisibility(R.id.no_habits_text, if (shown == 0) View.VISIBLE else View.GONE)
    }
}
