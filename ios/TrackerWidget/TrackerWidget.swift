import WidgetKit
import SwiftUI

// ─── Shared data models ────────────────────────────────────────────────────────

struct WidgetTask: Identifiable {
    let id    = UUID()
    let title: String
    let due: String
    let isOverdue: Bool
}

struct WidgetHabit: Identifiable {
    let id        = UUID()
    let name: String
    let streak: Int
    let doneToday: Bool
}

// ─── Shared UserDefaults loader ───────────────────────────────────────────────

private let appGroupId = "group.com.example.tracker"

private func loadTasks() -> [WidgetTask] {
    guard let d = UserDefaults(suiteName: appGroupId) else { return [] }
    var result: [WidgetTask] = []
    for i in 1...4 {
        let k = "task_\(i)"
        guard d.bool(forKey: "\(k)_visible") else { continue }
        result.append(WidgetTask(
            title:     d.string( forKey: "\(k)_title")   ?? "",
            due:       d.string( forKey: "\(k)_due")     ?? "",
            isOverdue: d.bool(   forKey: "\(k)_overdue")
        ))
    }
    return result
}

private func loadHabits() -> [WidgetHabit] {
    guard let d = UserDefaults(suiteName: appGroupId) else { return [] }
    var result: [WidgetHabit] = []
    for i in 1...5 {
        let k = "habit_\(i)"
        guard d.bool(forKey: "\(k)_visible") else { continue }
        result.append(WidgetHabit(
            name:      d.string(  forKey: "\(k)_name")   ?? "",
            streak:    d.integer( forKey: "\(k)_streak"),
            doneToday: d.bool(    forKey: "\(k)_done")
        ))
    }
    return result
}

private func loadTimestamp() -> String {
    UserDefaults(suiteName: appGroupId)?.string(forKey: "last_updated") ?? ""
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: – TASKS WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let timestamp: String
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [
            WidgetTask(title: "Buy groceries",  due: "Today",    isOverdue: false),
            WidgetTask(title: "Submit report",  due: "Tomorrow", isOverdue: false),
            WidgetTask(title: "Call dentist",   due: "Overdue",  isOverdue: true),
        ], timestamp: "9:41 AM")
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(TaskEntry(date: Date(), tasks: loadTasks(), timestamp: loadTimestamp()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = TaskEntry(date: Date(), tasks: loadTasks(), timestamp: loadTimestamp())
        let next  = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TaskWidgetView: View {
    var entry: TaskEntry

    var body: some View {
        ZStack {
            Color(red: 0.059, green: 0.067, blue: 0.090)
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Tasks")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(entry.timestamp)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.bottom, 7)

                Text("UPCOMING")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.506, green: 0.549, blue: 0.973))
                    .padding(.bottom, 6)

                if entry.tasks.isEmpty {
                    Text("All caught up! 🎉")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    ForEach(entry.tasks.prefix(4)) { task in
                        TaskRowView(task: task)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }
}

private struct TaskRowView: View {
    let task: WidgetTask

    private var dueColor: Color {
        if task.isOverdue || task.due == "Overdue" { return Color(red: 0.937, green: 0.267, blue: 0.267) }
        if task.due == "Today"    { return Color(red: 0.506, green: 0.549, blue: 0.973) }
        if task.due == "Tomorrow" { return Color(red: 0.984, green: 0.749, blue: 0.141) }
        return Color.white.opacity(0.5)
    }

    var body: some View {
        HStack(spacing: 7) {
            Text("●")
                .font(.system(size: 7))
                .foregroundColor(Color(red: 0.506, green: 0.549, blue: 0.973))
            Text(task.title)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            Text(task.due)
                .font(.system(size: 10))
                .foregroundColor(dueColor)
        }
        .padding(.bottom, 5)
    }
}

struct TrackerTaskWidget: Widget {
    let kind = "TrackerTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                TaskWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TaskWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Tasks")
        .description("Top tasks sorted by due date.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: – HABITS WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]
    let timestamp: String
}

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: [
            WidgetHabit(name: "Morning Run", streak: 12, doneToday: true),
            WidgetHabit(name: "Read",        streak: 5,  doneToday: false),
            WidgetHabit(name: "Meditate",    streak: 0,  doneToday: false),
        ], timestamp: "9:41 AM")
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(HabitEntry(date: Date(), habits: loadHabits(), timestamp: loadTimestamp()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = HabitEntry(date: Date(), habits: loadHabits(), timestamp: loadTimestamp())
        let next  = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct HabitWidgetView: View {
    var entry: HabitEntry

    var body: some View {
        ZStack {
            Color(red: 0.059, green: 0.067, blue: 0.090)
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Habits")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(entry.timestamp)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.bottom, 7)

                Text("TODAY'S STREAKS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.204, green: 0.827, blue: 0.600))
                    .padding(.bottom, 6)

                if entry.habits.isEmpty {
                    Text("No habits yet. Add some!")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    ForEach(entry.habits.prefix(5)) { habit in
                        HabitRowView(habit: habit)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }
}

private struct HabitRowView: View {
    let habit: WidgetHabit

    private var dotColor: Color {
        if habit.doneToday  { return Color(red: 0.204, green: 0.827, blue: 0.600) }
        if habit.streak > 0 { return Color(red: 0.506, green: 0.549, blue: 0.973) }
        return Color.white.opacity(0.25)
    }

    private var streakLabel: String {
        if habit.streak > 0 { return "🔥 \(habit.streak)d" }
        if habit.doneToday  { return "✓" }
        return "—"
    }

    private var streakColor: Color {
        habit.doneToday || habit.streak > 0
            ? Color(red: 0.204, green: 0.827, blue: 0.600)
            : Color.white.opacity(0.3)
    }

    var body: some View {
        HStack(spacing: 7) {
            Text("●")
                .font(.system(size: 8))
                .foregroundColor(dotColor)
            Text(habit.name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            Text(streakLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(streakColor)
        }
        .padding(.bottom, 5)
    }
}

struct TrackerHabitWidget: Widget {
    let kind = "TrackerHabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                HabitWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HabitWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Habits")
        .description("Today's habit streaks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
