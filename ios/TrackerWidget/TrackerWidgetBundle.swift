import WidgetKit
import SwiftUI

@main
struct TrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrackerTaskWidget()   // "Tasks" — top 4 by due date
        TrackerHabitWidget()  // "Habits" — today's streaks
    }
}
