import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskRepository {
  static const String _storageKey = 'task_matrix_tasks';
  final Uuid _uuid = const Uuid();

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      return Task.decodeList(jsonString);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = Task.encodeList(tasks);
    await prefs.setString(_storageKey, jsonString);
  }

  String generateId() {
    return _uuid.v4();
  }

  Future<Task> createTask({
    required String title,
    String? description,
    Quadrant? quadrant, // null = inbox item
    DateTime? dueDate,
  }) async {
    final tasks = await loadTasks();
    final task = Task(
      id: generateId(),
      title: title,
      description: description,
      quadrant: quadrant,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    tasks.add(task);
    await saveTasks(tasks);
    return task;
  }

  /// Quick add to inbox (minimal fields)
  Future<Task> addToInbox(String title) async {
    return createTask(title: title, quadrant: null);
  }

  Future<void> updateTask(Task updatedTask) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index].completed = !tasks[index].completed;
      await saveTasks(tasks);
    }
  }

  List<Task> filterTasks(List<Task> tasks, TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        // Exclude inbox items from "all" view (they show in inbox)
        return tasks.where((t) => t.quadrant != null).toList();
      case TaskFilter.active:
        return tasks.where((t) => !t.completed && t.quadrant != null).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.completed && t.quadrant != null).toList();
    }
  }

  /// Get all inbox items (tasks without quadrant)
  List<Task> getInboxTasks(List<Task> tasks) {
    return tasks.where((t) => t.isInbox && !t.completed).toList();
  }

  /// Get inbox item count
  int getInboxCount(List<Task> tasks) {
    return getInboxTasks(tasks).length;
  }

  List<Task> getTasksByQuadrant(List<Task> tasks, Quadrant quadrant) {
    return tasks.where((t) => t.quadrant == quadrant).toList();
  }

  List<Task> sortTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      // Active tasks first
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      // Tasks with due dates before tasks without
      if ((a.dueDate != null) != (b.dueDate != null)) {
        return a.dueDate != null ? -1 : 1;
      }
      // Sort by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      // Sort by creation date
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  /// Sort inbox items by creation date (newest first)
  List<Task> sortInboxItems(List<Task> items) {
    final sorted = List<Task>.from(items);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  // ===== Today View Helper Methods =====

  /// Get overdue tasks (past due date, not completed)
  List<Task> getOverdueTasks(List<Task> tasks) {
    return tasks.where((t) => t.isOverdue && !t.completed).toList();
  }

  /// Get tasks due today (not completed)
  List<Task> getTodayTasks(List<Task> tasks) {
    return tasks.where((t) => t.isDueToday && !t.completed).toList();
  }

  /// Get tasks due in the next N days (excluding today, not completed)
  List<Task> getUpcomingTasks(List<Task> tasks, {int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(Duration(days: days));

    return tasks.where((t) {
      if (t.dueDate == null || t.completed) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      // After today, before or on end date
      return dueDay.isAfter(today) && !dueDay.isAfter(endDate);
    }).toList();
  }

  /// Get all tasks with due dates (for "All" tab in Today view)
  List<Task> getScheduledTasks(List<Task> tasks) {
    return tasks.where((t) => t.dueDate != null && !t.isInbox).toList();
  }

  /// Get count for Today badge (overdue + due today)
  int getTodayCount(List<Task> tasks) {
    return getOverdueTasks(tasks).length + getTodayTasks(tasks).length;
  }

  /// Group tasks by date (for Upcoming view)
  Map<DateTime, List<Task>> groupTasksByDate(List<Task> tasks) {
    final Map<DateTime, List<Task>> grouped = {};
    for (final task in tasks) {
      if (task.dueDate == null) continue;
      final dateKey = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }
    return grouped;
  }
}

enum TaskFilter {
  all,
  active,
  completed,
}

extension TaskFilterExtension on TaskFilter {
  String get label {
    switch (this) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Done';
    }
  }
}
