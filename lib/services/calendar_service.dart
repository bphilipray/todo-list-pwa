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

  /// Get list of available calendars
  /// Returns a record with calendars and diagnostic info
  /// Note: We return ALL calendars now, as isReadOnly detection is unreliable on some devices
  Future<({List<Calendar> calendars, String? diagnosticInfo})> getCalendarsWithDiagnostics() async {
    if (!_hasPermissions) {
      final granted = await requestPermissions();
      if (!granted) {
        return (calendars: <Calendar>[], diagnosticInfo: 'Calendar permission not granted');
      }
    }

    final result = await _deviceCalendar.retrieveCalendars();
    if (result.isSuccess && result.data != null) {
      final allCalendars = result.data!;

      // Debug: Log all calendars for troubleshooting
      print('=== Found ${allCalendars.length} calendars ===');
      for (final cal in allCalendars) {
        print('Calendar: name="${cal.name}" | id="${cal.id}" | readOnly=${cal.isReadOnly} | account="${cal.accountName}" | type="${cal.accountType}"');
      }

      // Filter to only writable calendars with valid IDs
      final validCalendars = allCalendars
          .where((cal) =>
              cal.id != null &&
              cal.id!.isNotEmpty &&
              cal.isReadOnly != true)  // Only writable calendars
          .toList();

      print('=== ${validCalendars.length} writable calendars with valid IDs ===');

      if (validCalendars.isEmpty) {
        final totalCount = allCalendars.length;
        final readOnlyCount = allCalendars.where((c) => c.isReadOnly == true).length;
        return (
          calendars: <Calendar>[],
          diagnosticInfo: allCalendars.isEmpty
              ? 'No calendars found. Please install a calendar app (like Google Calendar) and add an account.'
              : 'Found $totalCount calendar(s) but $readOnlyCount are read-only (holidays). No writable calendars available.'
        );
      }

      // Sort calendars - prefer Google calendars first, then by name/account
      validCalendars.sort((a, b) {
        // Prioritize Google calendars
        final aIsGoogle = a.accountType?.toLowerCase().contains('google') ?? false;
        final bIsGoogle = b.accountType?.toLowerCase().contains('google') ?? false;
        if (aIsGoogle && !bIsGoogle) return -1;
        if (!aIsGoogle && bIsGoogle) return 1;
        // Then sort by account name or calendar name
        final aName = a.name ?? a.accountName ?? '';
        final bName = b.name ?? b.accountName ?? '';
        return aName.compareTo(bName);
      });

      return (calendars: validCalendars, diagnosticInfo: null);
    }

    return (
      calendars: <Calendar>[],
      diagnosticInfo: result.errors.isNotEmpty
          ? 'Error: ${result.errors.first.errorMessage}'
          : 'Failed to retrieve calendars'
    );
  }

  /// Get list of available writable calendars (simple version for backward compatibility)
  Future<List<Calendar>> getCalendars() async {
    final result = await getCalendarsWithDiagnostics();
    return result.calendars;
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

    // Set default values for fields that might cause null pointer exceptions
    // This fixes "Attempt to invoke virtual method 'int java.lang.Integer.intValue()' on a null object reference"
    event.reminders = []; // Empty reminders list instead of null
    event.availability = Availability.Busy;
    event.status = EventStatus.Confirmed;

    print('Calendar event created: title="${event.title}" start=${event.start} end=${event.end} allDay=${event.allDay}');

    return event;
  }
}
