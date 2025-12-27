# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter run -d chrome    # Run as web app
flutter build apk        # Build Android APK
flutter build ios        # Build iOS (requires macOS)
flutter build web        # Build for web deployment
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run single test file
flutter analyze          # Run static analysis
```

**Requirements:** Dart SDK ^3.10.1

## Architecture

### Overview
Task Matrix is an Eisenhower Matrix task manager built with Flutter. It uses a simple architecture with local persistence via SharedPreferences. Inspired by Things 3 (concept) + Apple Reminders (simplicity).

### Core Data Model

**`lib/models/task.dart`**
- `Subtask` class: id, title, completed (with `copyWith`, `toJson`, `fromJson`)
- `ReminderOffset` enum: `atTime`, `fiveMin`, `fifteenMin`, `thirtyMin`, `oneHour`, `oneDay`
- `ReminderOffsetExtension`: Provides `label` and `duration` for reminder offset calculations
- `RecurrenceType` enum: `none`, `daily`, `weekdays`, `weekly`, `monthly`
- `RecurrenceTypeExtension`: Provides `label` and `getNextDueDate()` for recurrence logic
- `Quadrant` enum: `urgentImportant`, `notUrgentImportant`, `urgentNotImportant`, `notUrgentNotImportant`
- `QuadrantExtension`: Provides `label` ("Do First", "Schedule", "Delegate", "Drop"), `description`, `isUrgent`, `isImportant`, and `fromFlags()` factory
- `Task` class: id, title, description, quadrant (nullable - null = inbox), completed, createdAt, dueDate, dueTimeHour, dueTimeMinute, subtasks, recurrence, reminderOffsets, calendarEventId
- Task helpers: `hasDueTime`, `hasSubtasks`, `isRecurring`, `isInbox`, `completedSubtasksCount`, `totalSubtasksCount`, `subtasksProgress`, `scheduledDateTime`, `reminderDateTimes`, `isOverdue`, `isDueToday`, `isDueTomorrow`, `daysUntilDue`

### Application Flow

```
main.dart (TaskMatrixApp)
    ├── [First Launch] OnboardingScreen (5-page intro)
    │       └── Completes → Creates first task in Inbox → MainScreen
    │
    └── [Normal Launch] MainScreen (StatefulWidget - manages global task state)
            ├── AppDrawer (navigation: Home, Today, Inbox)
            ├── HomeContent (matrix view with 4 quadrants)
            │       ├── FilterTabs (All/Active/Done filtering)
            │       └── 4x QuadrantSection (collapsible sections)
            │               └── TaskTile (swipe actions, tap to edit)
            ├── TodayScreen (Today/Upcoming/All tabs)
            │       └── TaskTile (reused)
            └── InboxScreen (quick capture + inbox items)
                    └── AddTaskSheet (bottom sheet for create/edit)
```

**State Management:** `MainScreen` maintains all task state in `List<Task> _tasks` and passes to child screens via props. No external state management library - uses `setState()` with repository pattern for persistence.

### Navigation System

**`lib/screens/main_screen.dart`**
- `AppScreen` enum: `home`, `today`, `inbox`
- Drawer-based navigation (not bottom tabs)
- Sidebar icon in AppBar opens drawer
- State lifted to MainScreen, shared across all screens

**`lib/widgets/app_drawer.dart`**
- Modern sidebar with app branding
- Navigation items: Home, Today (with badge), Inbox (with badge)
- Badge colors: Today = warning (orange), Inbox = sage green

### Repository Pattern

**`lib/repositories/task_repository.dart`**
- Persistence: SharedPreferences with key `'task_matrix_tasks'`
- Task JSON encoding/decoding handled by `Task.encodeList()` / `Task.decodeList()`
- Provides filtering (`filterTasks`), sorting (`sortTasks`), and CRUD operations
- `TaskFilter` enum: `all`, `active`, `completed`
- Task sorting: active tasks first → tasks with due dates → by due date → by creation date (newest first)
- Inbox helpers: `getInboxTasks()`, `getInboxCount()`, `sortInboxItems()`
- Today helpers: `getOverdueTasks()`, `getTodayTasks()`, `getUpcomingTasks()`, `getTodayCount()`, `groupTasksByDate()`

### Theme System

**`lib/theme/app_theme.dart`**
- Multi-theme support with 10 color themes (7 dark, 3 light)
- `AppColorTheme` class: Complete color definition for a theme (id, name, isDark, background, surface, surfaceLight, textPrimary, textSecondary, quadrant colors, status colors, accent)
- `AppThemes` class: Contains all preset themes as static constants
- `AppColors` class: Legacy static colors (Olive Dark) for backward compatibility
- `AppTheme.fromColorTheme()`: Generates Flutter `ThemeData` from an `AppColorTheme`

**Available Themes:**
| Theme | Type | Description |
|-------|------|-------------|
| Olive Dark | Dark | Default - calm olive/sage tones |
| Midnight | Dark | Deep blues, modern |
| Ocean | Dark | Teals, aquas, calming |
| Sunset | Dark | Warm oranges, corals |
| Forest | Dark | Natural greens, earth tones |
| Rose | Light | Playful pinks |
| Monochrome | Dark | Minimal grays |
| Light Classic | Light | Clean white, traditional |
| Dracula | Dark | Popular dev theme - purple/pink/cyan |
| Catppuccin | Light | Catppuccin Latte - soothing pastels |

**`lib/repositories/theme_repository.dart`**
- Persistence via SharedPreferences (key: `'selected_theme_id'`)
- `loadTheme()`: Returns saved theme or default (Olive Dark)
- `saveTheme()`: Persists selected theme

**Theme Provider (`lib/main.dart`):**
- `ThemeProvider` InheritedWidget provides theme to entire app
- `TaskMatrixAppState.setTheme()`: Changes theme and persists
- `context.appColors` extension: Access current theme colors from any widget
- System UI (status bar, nav bar) automatically adapts to theme brightness

**Theme Selector (Settings Screen):**
- Grid of theme tiles with color preview
- Shows background, accent, and quadrant colors
- Checkmark on selected theme
- Instant theme switching with haptic feedback

### Widget Interactions

- **Swipe left** on task: Delete (with confirmation)
- **Swipe right** on task: Toggle completion (or reschedule if recurring)
- **Tap** on task: Edit via bottom sheet
- **Quadrant headers**: Collapsible with animation
- **FAB**: Opens AddTaskSheet for new task
- **U/I toggles** on task tile: Quick quadrant change by toggling Urgent/Important flags
- **Search icon** in AppBar: Expands to search bar, filters tasks across all quadrants by title/description
- **Sidebar icon** in AppBar: Opens navigation drawer

### Notification System

**`lib/services/notification_service.dart`**
- Uses `flutter_local_notifications` for scheduling local notifications
- Timezone-aware scheduling via `timezone` and `flutter_timezone` packages
- Singleton pattern: `NotificationService()` returns same instance
- Notifications auto-cancel when task is completed or deleted
- Android permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `WAKE_LOCK`, `VIBRATE`

**Alarm-Style Notifications:**
- Uses dedicated alarm channel with `AudioAttributesUsage.alarm` (louder than regular notifications)
- `fullScreenIntent: true` - Wakes screen when phone is locked
- Custom vibration patterns (longer for urgent tasks)
- LED light indicators on supported devices
- Category set to `alarm` for Android system handling
- Max priority and importance level

**AndroidManifest Receivers:**
- `ScheduledNotificationReceiver` - Handles scheduled notification delivery
- `ScheduledNotificationBootReceiver` - Reschedules notifications after device reboot

**Custom Reminder Intervals (Multi-Select):**
- Users can select multiple reminder times relative to due time
- Options: At time of event, 5 min before, 15 min before, 30 min before, 1 hour before, 1 day before
- Reminder picker appears in AddTaskSheet only when due time is set
- Multi-select chip UI - tap to toggle each interval on/off
- Each selected interval schedules a separate notification
- Unique notification IDs: `task.id.hashCode + offset.index`
- Notification title changes based on offset ("Task Due" vs "Reminder: 15 minutes before")

**Flow:**
1. User sets due date + time in AddTaskSheet
2. User optionally selects reminder interval (defaults to "At time of event")
3. MainScreen calls `_notificationService.scheduleTaskNotification(task)`
4. Notification fires at `reminderDateTime` with task title and appropriate label
5. `showTestNotification()` available for debugging

### Inbox System

**Philosophy:** Reduce friction - capture thoughts without deciding "urgent/important". Process later.

**`lib/screens/inbox_screen.dart`**
- Quick capture text field at top ("What's on your mind?")
- List of inbox items below (tasks with `quadrant == null`)
- Tap item → AddTaskSheet → set U/I toggles → moves to quadrant
- Swipe to delete with confirmation

**Flow:**
1. User types thought in quick capture field
2. Task created with `quadrant: null` (inbox marker)
3. Later, user taps item → edits → sets priority → saves
4. Task now has quadrant → appears in Home matrix view

### Today View System

**`lib/screens/today_screen.dart`**
- Three tabs: Today, Upcoming, All
- **Today tab**: Overdue tasks + tasks due today (sorted by due time)
- **Upcoming tab**: Tasks due in next 7 days, grouped by date
- **All tab**: All scheduled tasks (active + completed)
- Shows current date in title (e.g., "Thursday, Dec 26")
- Empty states with friendly messages

**Repository helpers:**
- `getOverdueTasks()`, `getTodayTasks()`, `getUpcomingTasks(days: 7)`
- `getScheduledTasks()`, `getTodayCount()`, `groupTasksByDate()`

### Subtasks System

- Tasks can have a list of `Subtask` items (steps to complete)
- AddTaskSheet has "Steps" section for managing subtasks
- TaskTile shows progress bar with X/Y count when task has subtasks
- Subtasks persist with task data in SharedPreferences
- Subtasks carry over when recurring tasks reschedule (not reset)

### Recurring Tasks System

- Tasks can have recurrence: `none`, `daily`, `weekdays` (Mon-Fri), `weekly`, `monthly`
- Recurrence picker only appears in AddTaskSheet when due date is set
- When completing a recurring task: resets to incomplete with next due date (instead of marking done)
- TaskTile shows repeat icon for recurring tasks
- `RecurrenceTypeExtension.getNextDueDate()` calculates next occurrence
- Weekdays option skips Saturday/Sunday

### Search Feature

- Search icon in AppBar expands to full-width search TextField
- Real-time filtering as user types (searches title and description)
- Filters across all quadrants simultaneously
- Back arrow or clear button exits search mode

### Key Patterns

- `copyWith` pattern on Task for immutable updates
- Priority selection via two toggles (Urgent/Important) that map to quadrant via `QuadrantExtension.fromFlags()`
- Haptic feedback on user interactions (`HapticFeedback.selectionClick()`)
- Due date helpers: `isOverdue`, `isDueToday`, `isDueTomorrow`, `daysUntilDue`
- Nullable quadrant pattern: `quadrant == null` means inbox item

---

## Tags/Labels System

**`lib/models/tag.dart`**
- `TagColors` class: 10-color palette (sage, terracotta, gold, purple, blue, pink, teal, amber, lavender, cyan)
- `Tag` class: id, name, colorIndex
- `Tag.getColor()` returns Color from palette
- JSON serialization + `encodeList` / `decodeList` for persistence

**`lib/repositories/tag_repository.dart`**
- Persistence via SharedPreferences (key: `'task_matrix_tags'`)
- `createTag(name)` auto-assigns next color from rotating palette
- `sortTags()` alphabetically by name

**`lib/screens/tags_screen.dart`**
- Manage Tags screen accessible from drawer
- Add new tags with auto-assigned colors
- Inline editing (tap to edit name)
- Swipe to delete with confirmation (shows task count affected)
- Task count badges per tag

**`lib/widgets/tag_picker.dart`**
- Used in AddTaskSheet for selecting tags
- Tap to toggle selection (multi-select)
- "New" button for inline tag creation
- Chips show color dot + name + checkmark when selected

**Task Integration:**
- `Task.tagIds` field (List<String>)
- `Task.hasTags` getter
- TagPicker in AddTaskSheet
- Tag chips displayed on TaskTile (max 3 visible + "+N")

**Drawer Integration:**
- Tags section shows all tags with colored dots
- Tap tag to filter Home view by that tag
- "Clear" button when filter is active
- Task count badges per tag (uncompleted tasks only)

**Filtering:**
- Home screen accepts `selectedTagId` parameter
- Tag filter chip shown below filter tabs when active
- Click X on chip to clear filter

---

## Settings & Backup System

**`lib/screens/settings_screen.dart`**
- Settings screen accessible from drawer
- Cloud Sync section (Google Sign-In + sync)
- Local Backup section (Export/Import JSON)
- Statistics section (task counts)
- About section (app info)

**`lib/services/backup_service.dart`**
- `BackupData` class: version, exportedAt, tasks, tags
- `exportData()`: Creates JSON file and opens share sheet
- `importData()`: Picks JSON file, validates, returns parsed data
- JSON format includes version for future compatibility

**`lib/services/auth_service.dart`**
- Google Sign-In via Firebase Auth
- `signInWithGoogle()`, `signOut()`
- User info: `displayName`, `email`, `photoUrl`
- Auth state stream: `authStateChanges`

**`lib/services/cloud_sync_service.dart`**
- Firebase Firestore for cloud storage
- Data stored under `users/{userId}/tasks` and `users/{userId}/tags`
- `uploadAll()`: Push all local data to cloud
- `downloadAll()`: Pull all cloud data
- `sync()`: Merge local + cloud (local wins for conflicts)
- `getLastSyncTime()`: Retrieve last sync timestamp

**Firebase Configuration:**
- Project: `taskmatrix-app` (or user's project name)
- Auth: Google Sign-In enabled
- Database: Firestore in test mode
- Android: SHA-1 fingerprint added for Google Sign-In

---

## Calendar Sync System

**`lib/services/calendar_service.dart`**
- Singleton service for device calendar integration
- Uses `device_calendar` package (Android only currently)
- One-way sync: app → system calendar
- Persists settings via SharedPreferences (`calendar_sync_enabled`, `calendar_sync_calendar_id`)

**Sync Behavior:**
- Tasks with due date + time → Timed events (30 min duration)
- Tasks with due date only → All-day events
- Recurring tasks → Only sync next occurrence (not full recurrence rule)
- Completed tasks → Removed from calendar
- Deleted tasks → Removed from calendar

**Key Methods:**
- `initialize()` - Check permissions on startup
- `requestPermissions()` - Request calendar read/write access
- `getCalendars()` - List writable calendars
- `syncTask(task)` - Create/update calendar event, returns event ID
- `deleteEvent(eventId)` - Remove event from calendar
- `syncAllTasks(tasks)` - Bulk sync existing tasks

**Task Integration:**
- `Task.calendarEventId` field stores synced event ID
- `copyWith(clearCalendarEventId: true)` to clear event ID
- MainScreen triggers sync on task create/update/complete/delete

**Settings UI (`lib/screens/settings_screen.dart`):**
- Toggle switch to enable/disable calendar sync
- Dropdown to select target calendar
- "Sync All Tasks" button for bulk sync
- Dialog on disable: "Remove events" or "Keep events"

**Android Permissions (`AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.READ_CALENDAR"/>
<uses-permission android:name="android.permission.WRITE_CALENDAR"/>
```

---

## Cleanup System

**Settings UI (`lib/screens/settings_screen.dart`):**
- "Data Management" section in Settings
- "Delete Completed Tasks" button with confirmation dialog
- Auto-cleanup toggle with days selector (7, 14, 30 days)

**Auto-Cleanup Behavior:**
- Runs on app startup if enabled
- Deletes completed tasks older than X days (based on dueDate or createdAt)
- Also removes associated calendar events and cancels notifications
- Shows subtle snackbar notification when tasks are auto-cleaned

**Persistence:**
- Setting stored in SharedPreferences (`auto_cleanup_days`)
- `null` = disabled, integer = days threshold

**MainScreen Integration (`lib/screens/main_screen.dart`):**
- `_autoCleanupDays` state variable
- `_loadAutoCleanupSetting()` - loads setting and runs cleanup on startup
- `_saveAutoCleanupSetting()` - persists setting changes
- `_performAutoCleanup()` - deletes old completed tasks
- `_deleteCompletedTasks()` - bulk delete all completed tasks

---

## Onboarding System

**`lib/repositories/onboarding_repository.dart`**
- SharedPreferences flag management (`onboarding_completed` key)
- `isOnboardingCompleted()` - Check if first launch
- `markOnboardingCompleted()` - Set flag after onboarding
- `resetOnboarding()` - For debugging/re-triggering

**`lib/screens/onboarding_screen.dart`**
- 5-page PageView introducing app concepts
- Page 1: Welcome - App name + tagline
- Page 2: The Matrix - 2x2 quadrant explanation with colored boxes
- Page 3: Quick Capture - Inbox concept
- Page 4: Stay Focused - Today view concept
- Page 5: Get Started - Feature overview + optional first task creation
- `fromSettings` parameter - Shows Skip button when accessed from Settings
- `onComplete(String? firstTaskTitle)` callback - Passes optional first task to create

**First-Time User Flow:**
1. App checks `onboarding_completed` flag in `main.dart`
2. If false → Shows `OnboardingScreen` (no skip button)
3. User must complete all 5 slides
4. On final slide, can optionally enter first task
5. Task created in Inbox on completion
6. Flag set → Navigates to MainScreen

**Settings Integration:**
- "View Tutorial" button in About section of Settings
- Opens OnboardingScreen with `fromSettings: true`
- Skip button available for quick exit

**MainScreen Integration:**
- Accepts `initialTaskTitle` parameter from onboarding
- `_createInitialTaskIfNeeded()` - Creates inbox task after tasks load

---

## Voice Input System

**`lib/services/speech_service.dart`**
- Singleton service using `speech_to_text` package
- `initialize()` - Check speech recognition availability
- `startListening()` - Begin recording with callbacks for results and errors
- `stopListening()` - Stop recording manually
- `isAvailable` - Whether device supports speech recognition
- `isListening` - Whether currently recording

**`lib/widgets/voice_input_button.dart`**
- Reusable microphone button widget
- Visual feedback: icon changes + pulse animation when recording
- `compact` mode for inline use in text fields
- Callbacks: `onResult(text)`, `onError(error)`
- Haptic feedback on start/stop

**Integration Points:**
- **Inbox Screen** - Mic button next to Add button in quick capture
- **Add Task Sheet** - Mic button as suffixIcon in title TextField
- **MainScreen** - Initializes SpeechService on app startup

**Behavior:**
- Tap to start recording, tap again to stop
- Auto-stops after 3 seconds of silence
- Transcribed text appends to existing input
- Shows error snackbar on failure
- Button hidden if speech not available on device

**Android Permissions:**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

---

## Features To Consider (Future)

Features discussed but not yet implemented:

### Other Features
- **Home Screen Widget**: Quick access without opening app
- **TaskStats**: Statistics dashboard with completion %, overdue count, quadrant distribution
- **Bulk Actions**: Select multiple tasks to complete/delete/move at once
- **Reorder within Quadrant**: Manual drag to prioritize tasks within the same quadrant
- **DateRangeCalendar**: Calendar view for filtering tasks by date range

### Completed Features
- ~~Inbox/Quick Capture~~ (Done)
- ~~Today/Upcoming View~~ (Done)
- ~~Search~~ (Done)
- ~~Subtasks~~ (Done)
- ~~Recurring Tasks~~ (Done)
- ~~Notifications~~ (Done - Alarm-style)
- ~~Tags/Labels~~ (Done)
- ~~Local Export/Import~~ (Done)
- ~~Cloud Sync/Backup~~ (Done - Firebase)
- ~~Theme System~~ (Done - 10 themes: 7 dark, 3 light)
- ~~Custom Reminder Intervals~~ (Done - Multi-select: at time, 5/15/30 min, 1 hour, 1 day before)
- ~~Calendar Integration~~ (Done - One-way sync to device calendar, Android only)
- ~~Cleanup System~~ (Done - Delete completed tasks + auto-cleanup after X days)
- ~~Onboarding Flow~~ (Done - 5-page intro + optional first task + accessible from Settings)
- ~~Voice Input~~ (Done - Speech-to-text in Inbox + Add Task Sheet)
