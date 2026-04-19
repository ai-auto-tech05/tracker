# Tracker — Productivity, Habit & Focus App

A production-ready Flutter Android application for the Google Play Store combining task management, habit tracking, streak logic, and Pomodoro-style focus sessions.

---

## Architecture Overview

```
lib/
├── core/
│   ├── constants/       # Colors, strings, dimensions
│   ├── theme/           # Light + dark Material 3 themes
│   └── utils/           # Date helpers, streak calculations
├── models/              # Pure Dart models with toJson/fromJson
├── services/            # HiveService (local DB), NotificationService (stub)
├── providers/           # Riverpod StateNotifierProviders
├── navigation/          # GoRouter with redirect guard
├── screens/             # One folder per module
│   ├── onboarding/
│   ├── main_shell/      # Persistent bottom nav host
│   ├── dashboard/
│   ├── tasks/
│   ├── habits/
│   ├── focus/
│   ├── analytics/
│   └── settings/
└── widgets/             # Reusable, module-scoped widgets
    ├── common/
    ├── tasks/
    ├── habits/
    ├── focus/
    └── analytics/
```

## Tech Stack

| Concern | Package |
|---------|---------|
| State management | `flutter_riverpod` |
| Local persistence | `hive_flutter` (JSON-serialized) |
| Navigation | `go_router` |
| Charts | `fl_chart` |
| Typography | `google_fonts` (Inter) |
| Animations | `flutter_animate` |
| Progress rings | `percent_indicator` |
| ID generation | `uuid` |
| Date formatting | `intl` |

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Dart ≥ 3.2.0
- Android Studio or VS Code with Flutter extension

### Setup

```bash
# Install dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Build release APK
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release
```

### Fonts
The app uses `google_fonts` to load Inter at runtime. For production, download the Inter font family and place TTF files in `assets/fonts/` (already referenced in pubspec.yaml).

## Features

### Onboarding
- 4-page animated intro carousel
- Name capture with persistent user profile

### Dashboard
- Greeting with time-of-day context
- Streak fire banner (auto-shows when streak > 0)
- Today's progress card (tasks + habits + focus time)
- Quick action shortcuts (Focus, Add Task, Analytics)
- Today's tasks list (first 4)
- Today's habits checklist (first 5)

### Task Manager
- Create tasks with title, description, priority (Low/Medium/High/Urgent), due date
- Filter tabs: Today / All / Upcoming / Done / Overdue
- Swipe-to-delete with confirmation
- Overdue auto-detection on load
- Completion toggles with animated checkbox

### Habit Tracker
- Create habits with name, icon (16 options), color (8 options), frequency (Daily/Weekly)
- Daily check-in toggles
- Streak auto-computation (current + longest)
- Archive / delete habits
- Completion history stored as date-keyed map

### Focus Timer
- Pomodoro-style: Focus / Short Break / Long Break
- Animated circular ring progress indicator
- Pause / Resume / Stop controls
- Linked task selector
- Session persistence to Hive
- Today's session count + focus minutes display

### Analytics
- KPI cards: All-time focus, tasks done, app streak, best habit streak
- Weekly focus bar chart (fl_chart)
- Weekly habit completion rate chart
- Per-habit streak progress bars with 30-day completion rate
- Weekly totals summary row

### Settings
- Name editing
- Focus timer duration configuration (stepper controls)
- Dark mode toggle
- Notifications toggle
- Data export stub (ready for implementation)
- Clear all data with confirmation
- Premium upsell card

## Persistence Strategy

All data is stored locally using **Hive** with JSON serialization:

```dart
// Write
box.put(model.id, jsonEncode(model.toJson()));

// Read
TaskModel.fromJson(jsonDecode(box.get(id)));
```

Boxes:
- `user_box` — single user profile
- `task_box` — task records (key = task.id)
- `habit_box` — habit records (key = habit.id)
- `focus_box` — focus session records (key = session.id)
- `progress_box` — daily progress snapshots (key = 'yyyy-MM-dd')
- `settings_box` — app-level key-value settings

## Adding Firebase Sync (Future)

The architecture is designed to accept a cloud sync layer without structural changes:

1. Add `firebase_core`, `cloud_firestore`, `firebase_auth` to pubspec.yaml
2. Create `FirestoreService` mirroring the `HiveService` API
3. In each `StateNotifier`, call both local and remote service
4. Wrap providers with an online/offline toggle Provider

## Notifications (Future)

`NotificationService` is stubbed and ready for `flutter_local_notifications`:

1. Add `flutter_local_notifications` to pubspec.yaml
2. Implement `scheduleHabitReminder`, `showFocusComplete`, `cancelAll`
3. Wire up habit reminder times from the settings UI

## Play Store Checklist

- [ ] Replace `com.example.tracker` with your actual package name
- [ ] Add proper app icons (use `flutter_launcher_icons` package)
- [ ] Add a splash screen (use `flutter_native_splash` package)
- [ ] Configure signing key in `android/key.properties`
- [ ] Update `build.gradle` release signing config
- [ ] Set proper `versionCode` and `versionName` in `pubspec.yaml`
- [ ] Add Privacy Policy URL to Play Store listing
- [ ] Test on multiple Android versions (API 21–34)
- [ ] Run `flutter analyze` and fix any warnings
- [ ] Run `flutter build appbundle --release` and test the bundle
