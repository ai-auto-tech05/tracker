package com.example.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Native AppWidget that displays the user's top 4 tasks (sorted by due date)
 * and top 3 habit streaks. Data is written by Flutter via [HomeWidget.saveWidgetData].
 */
class TrackerWidgetReceiver : HomeWidgetProvider() {

    // ── Slot helpers ─────────────────────────────────────────────────────────

    private data class TaskSlot(
        val rowId: Int,
        val titleId: Int,
        val dueId: Int,
        val key: String,
    )

    private data class HabitSlot(
        val rowId: Int,
        val nameId: Int,
        val streakId: Int,
        val key: String,
    )

    // ── Widget update ─────────────────────────────────────────────────────────

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = buildViews(context, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildViews(context: Context, data: SharedPreferences): RemoteViews {
        return RemoteViews(context.packageName, R.layout.tracker_widget).apply {

            // ── Tap anywhere → open the app ──────────────────────────────────
            context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.let { intent ->
                    val pi = PendingIntent.getActivity(
                        context, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    setOnClickPendingIntent(R.id.widget_root, pi)
                }

            // ── Last updated ─────────────────────────────────────────────────
            setTextViewText(R.id.last_updated, data.getString("last_updated", "") ?: "")

            // ── Tasks ────────────────────────────────────────────────────────
            val taskSlots = listOf(
                TaskSlot(R.id.task_row_1, R.id.task_title_1, R.id.task_due_1, "task_1"),
                TaskSlot(R.id.task_row_2, R.id.task_title_2, R.id.task_due_2, "task_2"),
                TaskSlot(R.id.task_row_3, R.id.task_title_3, R.id.task_due_3, "task_3"),
                TaskSlot(R.id.task_row_4, R.id.task_title_4, R.id.task_due_4, "task_4"),
            )

            var visibleTaskCount = 0
            for (slot in taskSlots) {
                val visible = data.getBoolean("${slot.key}_visible", false)
                if (visible) {
                    visibleTaskCount++
                    setViewVisibility(slot.rowId, View.VISIBLE)
                    setTextViewText(
                        slot.titleId,
                        data.getString("${slot.key}_title", "") ?: "",
                    )
                    val due = data.getString("${slot.key}_due", "") ?: ""
                    val isOverdue = data.getBoolean("${slot.key}_overdue", false)
                    setTextViewText(slot.dueId, due)
                    setTextColor(slot.dueId, dueColor(due, isOverdue))
                } else {
                    setViewVisibility(slot.rowId, View.GONE)
                }
            }

            // "All caught up" placeholder when no tasks
            setViewVisibility(
                R.id.no_tasks_text,
                if (visibleTaskCount == 0) View.VISIBLE else View.GONE,
            )

            // ── Habits ───────────────────────────────────────────────────────
            val habitSlots = listOf(
                HabitSlot(R.id.habit_row_1, R.id.habit_name_1, R.id.habit_streak_1, "habit_1"),
                HabitSlot(R.id.habit_row_2, R.id.habit_name_2, R.id.habit_streak_2, "habit_2"),
                HabitSlot(R.id.habit_row_3, R.id.habit_name_3, R.id.habit_streak_3, "habit_3"),
            )

            for (slot in habitSlots) {
                val visible = data.getBoolean("${slot.key}_visible", false)
                if (visible) {
                    setViewVisibility(slot.rowId, View.VISIBLE)
                    setTextViewText(
                        slot.nameId,
                        data.getString("${slot.key}_name", "") ?: "",
                    )
                    val streak = data.getInt("${slot.key}_streak", 0)
                    val done = data.getBoolean("${slot.key}_done", false)
                    val streakText = when {
                        streak > 0 -> "🔥 ${streak}d"
                        done       -> "✓"
                        else       -> "—"
                    }
                    setTextViewText(slot.streakId, streakText)
                    setTextColor(
                        slot.streakId,
                        if (streak > 0 || done) 0xFF34D399.toInt() else 0xFF888888.toInt(),
                    )
                } else {
                    setViewVisibility(slot.rowId, View.GONE)
                }
            }
        }
    }

    // ── Colour helpers ────────────────────────────────────────────────────────

    private fun dueColor(due: String, isOverdue: Boolean): Int = when {
        isOverdue || due == "Overdue"  -> 0xFFEF4444.toInt()   // red
        due == "Today"                 -> 0xFF818CF8.toInt()   // indigo
        due == "Tomorrow"              -> 0xFFFBBF24.toInt()   // amber
        else                           -> 0xFF888888.toInt()   // muted
    }
}
