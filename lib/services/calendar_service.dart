import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();

  static const String _enabledKey = 'calendar_sync_enabled';
  static const String _calendarIdKey = 'calendar_sync_calendar_id';
  static const Duration _defaultEventDuration = Duration(minutes: 30);

  bool _isInitialized = false;
  bool _hasPermissions = false;

  /// Initialize the calendar service and check permissions
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _checkPermissions();
    _isInitialized = true;
  }

  Future<bool> _checkPermissions() async {
    final result = await _deviceCalendar.hasPermissions();
    _hasPermissions = result.data ?? false;
    return _hasPermissions;
  }

  /// Request calendar permissions from the user
  Future<bool> requestPermissions() async {
    final result = await _deviceCalendar.requestPermissions();
    _hasPermissions = result.data ?? false;
    return _hasPermissions;
  }

  bool get hasPermissions => _hasPermissions;

  // --- Settings Management ---

  /// Check if calendar sync is enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Enable or disable calendar sync
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Get the selected calendar ID
  Future<String?> getSelectedCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarIdKey);
  }

  /// Set the selected calendar ID
  Future<void> setSelectedCalendarId(String? calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    if (calendarId == null) {
      await prefs.remove(_calendarIdKey);
    } else {
      await prefs.setString(_calendarIdKey, calendarId);
    }
  }

  // --- Calendar Operations ---

  /// Get list of available writable calendars
  Future<List<Calendar>> getCalendars() async {
    if (!_hasPermissions) {
      final granted = await requestPermissions();
      if (!granted) return [];
    }

    final result = await _deviceCalendar.retrieveCalendars();
    if (result.isSuccess && result.data != null) {
      // Filter to only writable calendars
      return result.data!.where((cal) => cal.isReadOnly == false).toList();
    }
    return [];
  }

  /// Sync a single task to the calendar
  /// Returns the calendar event ID if successful, null otherwise
  Future<String?> syncTask(Task task) async {
    if (!await isEnabled()) return task.calendarEventId;

    final calendarId = await getSelectedCalendarId();
    if (calendarId == null) return task.calendarEventId;

    if (!_hasPermissions) {
      final granted = await requestPermissions();
      if (!granted) return task.calendarEventId;
    }

    // Don't sync tasks without due dates
    if (task.dueDate == null) {
      // If task had a calendar event, delete it
      if (task.calendarEventId != null) {
        await deleteEvent(task.calendarEventId!, calendarId);
      }
      return null;
    }

    // Don't sync completed tasks - remove from calendar if present
    if (task.completed) {
      if (task.calendarEventId != null) {
        await deleteEvent(task.calendarEventId!, calendarId);
      }
      return null;
    }

    try {
      final event = _taskToEvent(task, calendarId);

      // If task already has a calendar event, update it
      if (task.calendarEventId != null) {
        event.eventId = task.calendarEventId;
      }

      final result = await _deviceCalendar.createOrUpdateEvent(event);
      return result?.data;
    } catch (e) {
      // Log error but don't throw - sync failures shouldn't block task operations
      print('Calendar sync error: $e');
      return task.calendarEventId;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteEvent(String eventId, String? calendarId) async {
    calendarId ??= await getSelectedCalendarId();
    if (calendarId == null) return false;

    try {
      final result = await _deviceCalendar.deleteEvent(calendarId, eventId);
      return result.isSuccess;
    } catch (e) {
      print('Calendar delete error: $e');
      return false;
    }
  }

  /// Sync all tasks to the calendar (for initial sync or resync)
  /// Returns a record with synced count and failed count
  Future<({int synced, int failed, List<Task> updatedTasks})> syncAllTasks(
      List<Task> tasks) async {
    int synced = 0;
    int failed = 0;
    final List<Task> updatedTasks = [];

    for (final task in tasks) {
      // Skip tasks without due dates or completed tasks
      if (task.dueDate == null || task.completed) {
        updatedTasks.add(task);
        continue;
      }

      final eventId = await syncTask(task);
      if (eventId != null) {
        synced++;
        // Update task with new event ID if changed
        if (eventId != task.calendarEventId) {
          updatedTasks.add(task.copyWith(calendarEventId: eventId));
        } else {
          updatedTasks.add(task);
        }
      } else {
        failed++;
        updatedTasks.add(task);
      }
    }

    return (synced: synced, failed: failed, updatedTasks: updatedTasks);
  }

  /// Delete all synced events from calendar (when user disables sync)
  Future<int> deleteAllSyncedEvents(List<Task> tasks) async {
    final calendarId = await getSelectedCalendarId();
    if (calendarId == null) return 0;

    int deleted = 0;
    for (final task in tasks) {
      if (task.calendarEventId != null) {
        final success = await deleteEvent(task.calendarEventId!, calendarId);
        if (success) deleted++;
      }
    }
    return deleted;
  }

  /// Convert a Task to a Calendar Event
  Event _taskToEvent(Task task, String calendarId) {
    final event = Event(calendarId);

    event.title = task.title;

    // Build description with quadrant label
    final quadrantLabel = task.quadrant?.label ?? 'Inbox';
    if (task.description != null && task.description!.isNotEmpty) {
      event.description = '[$quadrantLabel] ${task.description}';
    } else {
      event.description = '[$quadrantLabel]';
    }

    if (task.hasDueTime) {
      // Timed event
      final startTime = task.scheduledDateTime!;
      event.start = tz.TZDateTime.from(startTime, tz.local);
      event.end = tz.TZDateTime.from(
        startTime.add(_defaultEventDuration),
        tz.local,
      );
      event.allDay = false;
    } else {
      // All-day event
      final dueDate = task.dueDate!;
      event.start = tz.TZDateTime(tz.local, dueDate.year, dueDate.month, dueDate.day);
      event.end = tz.TZDateTime(tz.local, dueDate.year, dueDate.month, dueDate.day);
      event.allDay = true;
    }

    return event;
  }
}
