import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Subtask {
  final String id;
  String title;
  bool completed;

  Subtask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? completed,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }

  static String generateId() => _uuid.v4();
}

enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  monthly,
}

enum ReminderOffset {
  atTime,
  fiveMin,
  fifteenMin,
  thirtyMin,
  oneHour,
  oneDay,
}

extension ReminderOffsetExtension on ReminderOffset {
  String get label {
    switch (this) {
      case ReminderOffset.atTime:
        return 'At time of event';
      case ReminderOffset.fiveMin:
        return '5 minutes before';
      case ReminderOffset.fifteenMin:
        return '15 minutes before';
      case ReminderOffset.thirtyMin:
        return '30 minutes before';
      case ReminderOffset.oneHour:
        return '1 hour before';
      case ReminderOffset.oneDay:
        return '1 day before';
    }
  }

  Duration get duration {
    switch (this) {
      case ReminderOffset.atTime:
        return Duration.zero;
      case ReminderOffset.fiveMin:
        return const Duration(minutes: 5);
      case ReminderOffset.fifteenMin:
        return const Duration(minutes: 15);
      case ReminderOffset.thirtyMin:
        return const Duration(minutes: 30);
      case ReminderOffset.oneHour:
        return const Duration(hours: 1);
      case ReminderOffset.oneDay:
        return const Duration(days: 1);
    }
  }
}

extension RecurrenceTypeExtension on RecurrenceType {
  String get label {
    switch (this) {
      case RecurrenceType.none:
        return 'None';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekdays:
        return 'Weekdays';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }

  DateTime? getNextDueDate(DateTime currentDueDate) {
    switch (this) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        return currentDueDate.add(const Duration(days: 1));
      case RecurrenceType.weekdays:
        // Skip to next weekday (Mon-Fri)
        var next = currentDueDate.add(const Duration(days: 1));
        // If Saturday (6), skip to Monday (+2 days)
        // If Sunday (7), skip to Monday (+1 day)
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurrenceType.weekly:
        return currentDueDate.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + 1,
          currentDueDate.day,
          currentDueDate.hour,
          currentDueDate.minute,
        );
    }
  }
}

enum Quadrant {
  urgentImportant,
  notUrgentImportant,
  urgentNotImportant,
  notUrgentNotImportant,
}

extension QuadrantExtension on Quadrant {
  String get label {
    switch (this) {
      case Quadrant.urgentImportant:
        return 'Do First';
      case Quadrant.notUrgentImportant:
        return 'Schedule';
      case Quadrant.urgentNotImportant:
        return 'Delegate';
      case Quadrant.notUrgentNotImportant:
        return 'Drop';
    }
  }

  String get description {
    switch (this) {
      case Quadrant.urgentImportant:
        return 'Urgent & Important';
      case Quadrant.notUrgentImportant:
        return 'Not Urgent & Important';
      case Quadrant.urgentNotImportant:
        return 'Urgent & Not Important';
      case Quadrant.notUrgentNotImportant:
        return 'Not Urgent & Not Important';
    }
  }

  bool get isUrgent {
    return this == Quadrant.urgentImportant ||
        this == Quadrant.urgentNotImportant;
  }

  bool get isImportant {
    return this == Quadrant.urgentImportant ||
        this == Quadrant.notUrgentImportant;
  }

  static Quadrant fromFlags({required bool urgent, required bool important}) {
    if (urgent && important) return Quadrant.urgentImportant;
    if (!urgent && important) return Quadrant.notUrgentImportant;
    if (urgent && !important) return Quadrant.urgentNotImportant;
    return Quadrant.notUrgentNotImportant;
  }
}

class Task {
  final String id;
  String title;
  String? description;
  Quadrant? quadrant; // null = inbox item
  bool completed;
  final DateTime createdAt;
  DateTime? dueDate;
  int? dueTimeHour;
  int? dueTimeMinute;
  List<Subtask> subtasks;
  RecurrenceType recurrence;
  List<String> tagIds;
  List<ReminderOffset> reminderOffsets;
  String? calendarEventId;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.quadrant, // nullable for inbox items
    this.completed = false,
    required this.createdAt,
    this.dueDate,
    this.dueTimeHour,
    this.dueTimeMinute,
    List<Subtask>? subtasks,
    this.recurrence = RecurrenceType.none,
    List<String>? tagIds,
    List<ReminderOffset>? reminderOffsets,
    this.calendarEventId,
  })  : subtasks = subtasks ?? [],
        tagIds = tagIds ?? [],
        reminderOffsets = reminderOffsets ?? [ReminderOffset.atTime];

  /// Returns true if this task is in the inbox (no quadrant assigned)
  bool get isInbox => quadrant == null;

  bool get hasDueTime => dueTimeHour != null && dueTimeMinute != null;

  bool get hasSubtasks => subtasks.isNotEmpty;

  bool get isRecurring => recurrence != RecurrenceType.none;

  bool get hasTags => tagIds.isNotEmpty;

  int get completedSubtasksCount => subtasks.where((s) => s.completed).length;

  int get totalSubtasksCount => subtasks.length;

  double get subtasksProgress =>
      hasSubtasks ? completedSubtasksCount / totalSubtasksCount : 0.0;

  DateTime? get scheduledDateTime {
    if (dueDate == null) return null;
    if (!hasDueTime) return dueDate;
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTimeHour!,
      dueTimeMinute!,
    );
  }

  /// Returns true if this task has any reminder offsets set
  bool get hasReminders => reminderOffsets.isNotEmpty;

  /// Returns all reminder times for this task
  /// (scheduledDateTime minus each reminderOffset)
  List<DateTime> get reminderDateTimes {
    final scheduled = scheduledDateTime;
    if (scheduled == null) return [];
    return reminderOffsets
        .map((offset) => scheduled.subtract(offset.duration))
        .toList();
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Quadrant? quadrant,
    bool? completed,
    DateTime? createdAt,
    DateTime? dueDate,
    int? dueTimeHour,
    int? dueTimeMinute,
    List<Subtask>? subtasks,
    RecurrenceType? recurrence,
    List<String>? tagIds,
    List<ReminderOffset>? reminderOffsets,
    String? calendarEventId,
    bool clearDueDate = false,
    bool clearDueTime = false,
    bool clearCalendarEventId = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      quadrant: quadrant ?? this.quadrant,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTimeHour: clearDueTime ? null : (dueTimeHour ?? this.dueTimeHour),
      dueTimeMinute: clearDueTime ? null : (dueTimeMinute ?? this.dueTimeMinute),
      subtasks: subtasks ?? this.subtasks,
      recurrence: recurrence ?? this.recurrence,
      tagIds: tagIds ?? this.tagIds,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      calendarEventId: clearCalendarEventId ? null : (calendarEventId ?? this.calendarEventId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'quadrant': quadrant?.index, // null for inbox items
      'completed': completed,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'dueTimeHour': dueTimeHour,
      'dueTimeMinute': dueTimeMinute,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'recurrence': recurrence.index,
      'tagIds': tagIds,
      'reminderOffsets': reminderOffsets.map((o) => o.index).toList(),
      'calendarEventId': calendarEventId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility: old tasks have 'reminderOffset' (single),
    // new tasks have 'reminderOffsets' (list)
    List<ReminderOffset> offsets;
    if (json['reminderOffsets'] != null) {
      offsets = (json['reminderOffsets'] as List<dynamic>)
          .map((i) => ReminderOffset.values[i as int])
          .toList();
    } else if (json['reminderOffset'] != null) {
      // Migrate old single offset to list
      offsets = [ReminderOffset.values[json['reminderOffset'] as int]];
    } else {
      offsets = [ReminderOffset.atTime];
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      quadrant: json['quadrant'] != null
          ? Quadrant.values[json['quadrant'] as int]
          : null, // null = inbox item
      completed: json['completed'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int)
          : null,
      dueTimeHour: json['dueTimeHour'] as int?,
      dueTimeMinute: json['dueTimeMinute'] as int?,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      recurrence: json['recurrence'] != null
          ? RecurrenceType.values[json['recurrence'] as int]
          : RecurrenceType.none,
      tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>() ?? [],
      reminderOffsets: offsets,
      calendarEventId: json['calendarEventId'] as String?,
    );
  }

  static String encodeList(List<Task> tasks) {
    return jsonEncode(tasks.map((t) => t.toJson()).toList());
  }

  static List<Task> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Task.fromJson(json)).toList();
  }

  bool get isOverdue {
    if (dueDate == null || completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }
}
