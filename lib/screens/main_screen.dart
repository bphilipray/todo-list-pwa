import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../repositories/tag_repository.dart';
import '../repositories/task_repository.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';
import '../services/speech_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/add_task_sheet.dart';
import 'home_screen.dart';
import 'inbox_screen.dart';
import 'settings_screen.dart';
import 'tags_screen.dart';
import 'today_screen.dart';

enum AppScreen { home, today, inbox, tags, settings }

class MainScreen extends StatefulWidget {
  /// Optional task title from onboarding to add to inbox
  final String? initialTaskTitle;

  const MainScreen({super.key, this.initialTaskTitle});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TaskRepository _repository = TaskRepository();
  final TagRepository _tagRepository = TagRepository();
  final NotificationService _notificationService = NotificationService();
  final CalendarService _calendarService = CalendarService();
  final SpeechService _speechService = SpeechService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Task> _tasks = [];
  List<Tag> _tags = [];
  bool _isLoading = true;
  AppScreen _currentScreen = AppScreen.home;
  String? _selectedTagId;
  int? _autoCleanupDays;

  static const String _autoCleanupKey = 'auto_cleanup_days';

  @override
  void initState() {
    super.initState();
    _loadTasks().then((_) => _createInitialTaskIfNeeded());
    _loadTags();
    _loadAutoCleanupSetting();
    _requestNotificationPermissions();
    _initializeCalendarService();
    _initializeSpeechService();
  }

  Future<void> _initializeSpeechService() async {
    await _speechService.initialize();
  }

  /// Create a task from onboarding if initialTaskTitle was provided
  void _createInitialTaskIfNeeded() {
    if (widget.initialTaskTitle != null && widget.initialTaskTitle!.isNotEmpty) {
      _addTask(
        widget.initialTaskTitle!,
        null, // no description
        null, // inbox (no quadrant)
        null, // no due date
        null, // no due time hour
        null, // no due time minute
        [], // no subtasks
        RecurrenceType.none,
        [], // no tags
        [ReminderOffset.atTime], // default reminder
      );
    }
  }

  Future<void> _initializeCalendarService() async {
    await _calendarService.initialize();
  }

  Future<void> _requestNotificationPermissions() async {
    await _notificationService.requestPermissions();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _repository.loadTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    await _repository.saveTasks(_tasks);
  }

  Future<void> _loadTags() async {
    final tags = await _tagRepository.loadTags();
    setState(() => _tags = tags);
  }

  Future<void> _saveTags() async {
    await _tagRepository.saveTags(_tags);
  }

  void _createTag(String name) {
    final tag = _tagRepository.createTag(name);
    setState(() => _tags.add(tag));
    _saveTags();
  }

  void _updateTag(Tag tag, String newName) {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      final updatedTag = tag.copyWith(name: newName);
      setState(() => _tags[index] = updatedTag);
      _saveTags();
    }
  }

  void _deleteTag(Tag tag) {
    // Remove tag from all tasks
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].tagIds.contains(tag.id)) {
        _tasks[i] = _tasks[i].copyWith(
          tagIds: _tasks[i].tagIds.where((id) => id != tag.id).toList(),
        );
      }
    }
    _saveTasks();

    // Remove the tag itself
    setState(() => _tags.removeWhere((t) => t.id == tag.id));
    _saveTags();

    // Clear filter if this tag was selected
    if (_selectedTagId == tag.id) {
      setState(() => _selectedTagId = null);
    }
  }

  void _restoreBackup(List<Task> tasks, List<Tag> tags) {
    setState(() {
      _tasks = tasks;
      _tags = tags;
      _selectedTagId = null;
    });
    _saveTasks();
    _saveTags();

    // Cancel all existing notifications and reschedule for new tasks
    _notificationService.cancelAllNotifications();
    for (final task in _tasks) {
      if (!task.completed && task.quadrant != null) {
        _notificationService.scheduleTaskNotification(task);
      }
    }
  }

  // --- Calendar Sync Methods ---

  Future<void> _syncTaskToCalendar(Task task) async {
    if (!await _calendarService.isEnabled()) return;

    final eventId = await _calendarService.syncTask(task);
    if (eventId != null && eventId != task.calendarEventId) {
      // Update task with new event ID
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        setState(() {
          _tasks[index] = task.copyWith(calendarEventId: eventId);
        });
        _saveTasks();
      }
    } else if (eventId == null && task.calendarEventId != null) {
      // Event was deleted (task completed or has no due date)
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        setState(() {
          _tasks[index] = task.copyWith(clearCalendarEventId: true);
        });
        _saveTasks();
      }
    }
  }

  Future<void> _removeTaskFromCalendar(Task task) async {
    if (task.calendarEventId == null) return;

    await _calendarService.deleteEvent(task.calendarEventId!, null);

    // Clear the event ID from task
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      setState(() {
        _tasks[index] = task.copyWith(clearCalendarEventId: true);
      });
      _saveTasks();
    }
  }

  void _clearAllCalendarEventIds() {
    bool hasChanges = false;
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].calendarEventId != null) {
        _tasks[i] = _tasks[i].copyWith(clearCalendarEventId: true);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      setState(() {});
      _saveTasks();
    }
  }

  void _updateTasksFromCalendarSync(List<Task> updatedTasks) {
    setState(() {
      _tasks = updatedTasks;
    });
    _saveTasks();
  }

  // --- Auto-Cleanup Methods ---

  Future<void> _loadAutoCleanupSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt(_autoCleanupKey);
    setState(() {
      _autoCleanupDays = days;
    });
    // Run auto-cleanup after loading setting
    if (days != null) {
      _performAutoCleanup(days);
    }
  }

  Future<void> _saveAutoCleanupSetting(int? days) async {
    final prefs = await SharedPreferences.getInstance();
    if (days == null) {
      await prefs.remove(_autoCleanupKey);
    } else {
      await prefs.setInt(_autoCleanupKey, days);
    }
    setState(() {
      _autoCleanupDays = days;
    });
  }

  void _performAutoCleanup(int days) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: days));
    int deletedCount = 0;

    // Find tasks that are completed and were completed more than X days ago
    // Since we don't track completion date, we use the task's due date or creation date
    // For simplicity, we'll use: completed tasks older than X days based on dueDate or createdAt
    final tasksToDelete = _tasks.where((task) {
      if (!task.completed) return false;
      // Use dueDate if available, otherwise createdAt
      final referenceDate = task.dueDate ?? task.createdAt;
      return referenceDate.isBefore(cutoffDate);
    }).toList();

    if (tasksToDelete.isEmpty) return;

    for (final task in tasksToDelete) {
      // Remove from calendar if synced
      if (task.calendarEventId != null) {
        _calendarService.deleteEvent(task.calendarEventId!, null);
      }
      // Cancel any notifications
      _notificationService.cancelNotification(task.id);
    }

    setState(() {
      _tasks.removeWhere((t) => tasksToDelete.any((d) => d.id == t.id));
    });
    _saveTasks();

    deletedCount = tasksToDelete.length;
    if (deletedCount > 0 && mounted) {
      // Show a subtle notification about auto-cleanup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final colors = context.appColors;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-cleaned $deletedCount old completed task${deletedCount == 1 ? '' : 's'}'),
              backgroundColor: colors.surface,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  void _deleteCompletedTasks(int count) {
    final completedTasks = _tasks.where((t) => t.completed).toList();

    for (final task in completedTasks) {
      // Remove from calendar if synced
      if (task.calendarEventId != null) {
        _calendarService.deleteEvent(task.calendarEventId!, null);
      }
      // Cancel any notifications
      _notificationService.cancelNotification(task.id);
    }

    setState(() {
      _tasks.removeWhere((t) => t.completed);
    });
    _saveTasks();
  }

  void _selectTag(String? tagId) {
    setState(() {
      _selectedTagId = tagId;
      // If a tag is selected, go to home screen to show filtered tasks
      if (tagId != null && _currentScreen != AppScreen.home) {
        _currentScreen = AppScreen.home;
      }
    });
  }

  void _addTask(
    String title,
    String? description,
    Quadrant? quadrant,
    DateTime? dueDate,
    int? dueTimeHour,
    int? dueTimeMinute,
    List<Subtask> subtasks,
    RecurrenceType recurrence,
    List<String> tagIds,
    List<ReminderOffset> reminderOffsets,
  ) {
    final task = Task(
      id: _repository.generateId(),
      title: title,
      description: description,
      quadrant: quadrant,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      dueTimeHour: dueTimeHour,
      dueTimeMinute: dueTimeMinute,
      subtasks: subtasks,
      recurrence: recurrence,
      tagIds: tagIds,
      reminderOffsets: reminderOffsets,
    );
    setState(() => _tasks.add(task));
    _saveTasks();
    // Schedule notification for all tasks with due dates (including inbox items)
    _notificationService.scheduleTaskNotification(task);
    // Sync to calendar
    _syncTaskToCalendar(task);
  }

  void _addToInbox(String title) {
    // Default to "at time" reminder for inbox tasks
    _addTask(title, null, null, null, null, null, [], RecurrenceType.none, [], [ReminderOffset.atTime]);
  }

  void _updateTask(
    Task task,
    String title,
    String? description,
    Quadrant? quadrant,
    DateTime? dueDate,
    int? dueTimeHour,
    int? dueTimeMinute,
    List<Subtask> subtasks,
    RecurrenceType recurrence,
    List<String> tagIds,
    List<ReminderOffset> reminderOffsets,
  ) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final updatedTask = task.copyWith(
        title: title,
        description: description,
        quadrant: quadrant,
        dueDate: dueDate,
        dueTimeHour: dueTimeHour,
        dueTimeMinute: dueTimeMinute,
        subtasks: subtasks,
        recurrence: recurrence,
        tagIds: tagIds,
        reminderOffsets: reminderOffsets,
        clearDueDate: dueDate == null,
        clearDueTime: dueTimeHour == null,
      );
      setState(() {
        _tasks[index] = updatedTask;
      });
      _saveTasks();
      _notificationService.scheduleTaskNotification(updatedTask);
      // Sync to calendar
      _syncTaskToCalendar(updatedTask);
    }
  }

  void _toggleTaskComplete(Task task) {
    final colors = context.appColors;
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      // Handle recurring tasks
      if (task.isRecurring && !task.completed && task.dueDate != null) {
        final nextDueDate = task.recurrence.getNextDueDate(task.dueDate!);
        final updatedTask = task.copyWith(
          dueDate: nextDueDate,
          completed: false,
        );
        setState(() {
          _tasks[index] = updatedTask;
        });
        _saveTasks();
        _notificationService.scheduleTaskNotification(updatedTask);
        // Sync rescheduled task to calendar
        _syncTaskToCalendar(updatedTask);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recurring task rescheduled'),
            backgroundColor: colors.surface,
          ),
        );
      } else {
        final updatedTask = task.copyWith(completed: !task.completed);
        setState(() {
          _tasks[index] = updatedTask;
        });
        _saveTasks();
        _notificationService.scheduleTaskNotification(updatedTask);
        // Sync to calendar (will remove if completed, or add back if uncompleted)
        _syncTaskToCalendar(updatedTask);
      }
    }
  }

  void _toggleTaskUrgent(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final currentQuadrant = task.quadrant;
      if (currentQuadrant == null) return; // Don't toggle for inbox items

      final isCurrentlyUrgent = currentQuadrant.isUrgent;
      final isImportant = currentQuadrant.isImportant;
      final newQuadrant = QuadrantExtension.fromFlags(
        urgent: !isCurrentlyUrgent,
        important: isImportant,
      );
      final updatedTask = task.copyWith(quadrant: newQuadrant);
      setState(() {
        _tasks[index] = updatedTask;
      });
      _saveTasks();
    }
  }

  void _toggleTaskImportant(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final currentQuadrant = task.quadrant;
      if (currentQuadrant == null) return; // Don't toggle for inbox items

      final isUrgent = currentQuadrant.isUrgent;
      final isCurrentlyImportant = currentQuadrant.isImportant;
      final newQuadrant = QuadrantExtension.fromFlags(
        urgent: isUrgent,
        important: !isCurrentlyImportant,
      );
      final updatedTask = task.copyWith(quadrant: newQuadrant);
      setState(() {
        _tasks[index] = updatedTask;
      });
      _saveTasks();
    }
  }

  void _deleteTask(Task task) {
    final colors = context.appColors;
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _saveTasks();
    _notificationService.cancelNotification(task.id);
    // Remove from calendar
    _removeTaskFromCalendar(task);

    // Use global ScaffoldMessenger key to handle nested scaffolds
    final messenger = TaskMatrixAppState.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    // Clear any existing snackbars first
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text('Task deleted', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.surface,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: colors.notUrgentImportant,
          onPressed: () {
            setState(() => _tasks.add(task));
            _saveTasks();
            _notificationService.scheduleTaskNotification(task);
            // Re-sync to calendar on undo
            _syncTaskToCalendar(task);
          },
        ),
      ),
    );
  }

  void _showAddTaskSheet({Task? existingTask}) {
    final colors = context.appColors;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddTaskSheet(
        existingTask: existingTask,
        availableTags: _tags,
        onSave: (title, description, quadrant, dueDate, dueTimeHour,
            dueTimeMinute, subtasks, recurrence, tagIds, reminderOffsets) {
          if (existingTask != null) {
            _updateTask(existingTask, title, description, quadrant, dueDate,
                dueTimeHour, dueTimeMinute, subtasks, recurrence, tagIds, reminderOffsets);
          } else {
            _addTask(title, description, quadrant, dueDate, dueTimeHour,
                dueTimeMinute, subtasks, recurrence, tagIds, reminderOffsets);
          }
        },
        onCreateTag: (name) {
          _createTag(name);
          // Rebuild the bottom sheet to show the new tag
          Navigator.of(context).pop();
          _showAddTaskSheet(existingTask: existingTask);
        },
      ),
    );
  }

  void _navigateTo(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
    Navigator.of(context).pop(); // Close drawer
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  int get _inboxCount => _repository.getInboxCount(_tasks);
  int get _todayCount => _repository.getTodayCount(_tasks);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentScreen: _currentScreen,
        inboxCount: _inboxCount,
        todayCount: _todayCount,
        tags: _tags,
        tasks: _tasks,
        selectedTagId: _selectedTagId,
        onNavigate: _navigateTo,
        onSelectTag: _selectTag,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.surfaceLight),
            )
          : _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.home:
        return HomeContent(
          tasks: _tasks,
          tags: _tags,
          selectedTagId: _selectedTagId,
          repository: _repository,
          onToggleComplete: _toggleTaskComplete,
          onEdit: _showAddTaskSheet,
          onDelete: _deleteTask,
          onToggleUrgent: _toggleTaskUrgent,
          onToggleImportant: _toggleTaskImportant,
          onOpenDrawer: _openDrawer,
          onRefresh: _loadTasks,
          onAddTask: () => _showAddTaskSheet(),
          onClearTagFilter: () => _selectTag(null),
        );
      case AppScreen.today:
        return TodayScreen(
          tasks: _tasks,
          tags: _tags,
          repository: _repository,
          onToggleComplete: _toggleTaskComplete,
          onEdit: _showAddTaskSheet,
          onDelete: _deleteTask,
          onToggleUrgent: _toggleTaskUrgent,
          onToggleImportant: _toggleTaskImportant,
          onOpenDrawer: _openDrawer,
        );
      case AppScreen.inbox:
        return InboxScreen(
          tasks: _tasks,
          tags: _tags,
          repository: _repository,
          onAddToInbox: _addToInbox,
          onEdit: _showAddTaskSheet,
          onDelete: _deleteTask,
          onOpenDrawer: _openDrawer,
        );
      case AppScreen.tags:
        return TagsScreen(
          tags: _tags,
          tasks: _tasks,
          onCreateTag: _createTag,
          onUpdateTag: _updateTag,
          onDeleteTag: _deleteTag,
          onOpenDrawer: _openDrawer,
        );
      case AppScreen.settings:
        return SettingsScreen(
          tasks: _tasks,
          tags: _tags,
          onOpenDrawer: _openDrawer,
          onRestoreBackup: _restoreBackup,
          onClearCalendarEventIds: _clearAllCalendarEventIds,
          onCalendarSyncComplete: _updateTasksFromCalendarSync,
          onDeleteCompletedTasks: _deleteCompletedTasks,
          autoCleanupDays: _autoCleanupDays,
          onAutoCleanupChanged: _saveAutoCleanupSetting,
        );
    }
  }
}
