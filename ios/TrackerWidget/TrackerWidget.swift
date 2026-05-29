import WidgetKit
import SwiftUI

// ─── Shared data models ────────────────────────────────────────────────────────

struct WidgetTask: Identifiable {
    let id = UUID()
    let title: String
    let due: String
    let isOverdue: Bool
}

struct WidgetHabit: Identifiable {
    let id = UUID()
    let name: String
    let streak: Int
    let doneToday: Bool
}

// ─── Timeline entry ────────────────────────────────────────────────────────────

struct TrackerEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let habits: [WidgetHabit]
    let lastUpdated: String
}

// ─── Data provider ────────────────────────────────────────────────────────────

struct TrackerProvider: TimelineProvider {

    private let appGroupId = "group.com.example.tracker"

    func placeholder(in context: Context) -> TrackerEntry {
        TrackerEntry(
            date: Date(),
            tasks: [
                WidgetTask(title: "Buy groceries",  due: "Today",    isOverdue: false),
                WidgetTask(title: "Submit report",  due: "Tomorrow", isOverdue: false),
                WidgetTask(title: "Call dentist",   due: "Overdue",  isOverdue: true),
            ],
            habits: [
                WidgetHabit(name: "Morning Run", streak: 7,  doneToday: true),
                WidgetHabit(name: "Read",        streak: 3,  doneToday: false),
                WidgetHabit(name: "Meditate",    streak: 0,  doneToday: false),
            ],
            lastUpdated: "9:41 AM"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TrackerEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrackerEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 min as a fallback; Flutter calls updateWidget explicitly on changes.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }

    // ── Load from shared UserDefaults ──────────────────────────────────────

    private func loadEntry() -> TrackerEntry {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return placeholder(in: .init(isPreview: false))
        }

        var tasks: [WidgetTask] = []
        for i in 1...4 {
            let key = "task_\(i)"
            guard defaults.bool(forKey: "\(key)_visible") else { continue }
            tasks.append(WidgetTask(
                title:     defaults.string(forKey: "\(key)_title")    ?? "",
                due:       defaults.string(forKey: "\(key)_due")      ?? "",
                isOverdue: defaults.bool(  forKey: "\(key)_overdue")
            ))
        }

        var habits: [WidgetHabit] = []
        for i in 1...3 {
            let key = "habit_\(i)"
            guard defaults.bool(forKey: "\(key)_visible") else { continue }
            habits.append(WidgetHabit(
                name:      defaults.string(  forKey: "\(key)_name")   ?? "",
                streak:    defaults.integer( forKey: "\(key)_streak"),
                doneToday: defaults.bool(    forKey: "\(key)_done")
            ))
        }

        let updated = defaults.string(forKey: "last_updated") ?? ""
        return TrackerEntry(date: Date(), tasks: tasks, habits: habits, lastUpdated: updated)
    }
}

// ─── Views ────────────────────────────────────────────────────────────────────

struct TrackerWidgetView: View {
    var entry: TrackerEntry

    var body: some View {
        ZStack {
            Color(red: 0.059, green: 0.067, blue: 0.090) // #0F1117

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    Text("Tracker")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if !entry.lastUpdated.isEmpty {
                        Text(entry.lastUpdated)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(.bottom, 8)

                // TASKS
                Label("TASKS", systemImage: "")
                    .labelStyle(.titleOnly)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.506, green: 0.549, blue: 0.973))
                    .padding(.bottom, 5)

                if entry.tasks.isEmpty {
                    Text("All caught up! 🎉")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 4)
                } else {
                    ForEach(entry.tasks.prefix(4)) { task in
                        TaskRowView(task: task)
                    }
                }

                // Divider
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 6)

                // HABITS
                Text("HABITS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.204, green: 0.827, blue: 0.600))
                    .padding(.bottom, 5)

                ForEach(entry.habits.prefix(3)) { habit in
                    HabitRowView(habit: habit)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }
}

struct TaskRowView: View {
    let task: WidgetTask

    private var dueColor: Color {
        if task.isOverdue || task.due == "Overdue" {
            return Color(red: 0.937, green: 0.267, blue: 0.267)
        }
        if task.due == "Today"    { return Color(red: 0.506, green: 0.549, blue: 0.973) }
        if task.due == "Tomorrow" { return Color(red: 0.984, green: 0.749, blue: 0.141) }
        return Color.white.opacity(0.5)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("●")
                .font(.system(size: 7))
                .foregroundColor(Color(red: 0.506, green: 0.549, blue: 0.973))
            Text(task.title)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            Text(task.due)
                .font(.system(size: 10))
                .foregroundColor(dueColor)
        }
        .padding(.bottom, 4)
    }
}

struct HabitRowView: View {
    let habit: WidgetHabit

    private var streakLabel: String {
        if habit.streak > 0 { return "🔥 \(habit.streak)d" }
        if habit.doneToday  { return "✓" }
        return "—"
    }

    private var streakColor: Color {
        habit.streak > 0 || habit.doneToday
            ? Color(red: 0.204, green: 0.827, blue: 0.600)
            : Color.white.opacity(0.4)
    }

    var body: some View {
        HStack {
            Text(habit.name)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            Text(streakLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(streakColor)
        }
        .padding(.bottom, 4)
    }
}

// ─── Widget definition ────────────────────────────────────────────────────────

struct TrackerWidget: Widget {
    let kind = "TrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrackerProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                TrackerWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TrackerWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Tracker")
        .description("Top tasks and habit streaks.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
