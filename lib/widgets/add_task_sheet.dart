import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import 'tag_picker.dart';
import 'voice_input_button.dart';

class AddTaskSheet extends StatefulWidget {
  final Task? existingTask;
  final List<Tag> availableTags;
  final Function(String title, String? description, Quadrant? quadrant,
      DateTime? dueDate, int? dueTimeHour, int? dueTimeMinute,
      List<Subtask> subtasks, RecurrenceType recurrence, List<String> tagIds,
      List<ReminderOffset> reminderOffsets) onSave;
  final Function(String name) onCreateTag;

  const AddTaskSheet({
    super.key,
    this.existingTask,
    required this.availableTags,
    required this.onSave,
    required this.onCreateTag,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _subtaskController;
  late bool _isUrgent;
  late bool _isImportant;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  List<Subtask> _subtasks = [];
  RecurrenceType _recurrence = RecurrenceType.none;
  List<String> _selectedTagIds = [];
  List<ReminderOffset> _selectedReminderOffsets = [ReminderOffset.atTime];

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTask?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingTask?.description ?? '');
    _subtaskController = TextEditingController();

    // Handle inbox items (null quadrant) - default to false for both
    // For new tasks, default to urgent+important (Do First quadrant)
    final existingQuadrant = widget.existingTask?.quadrant;
    if (existingQuadrant != null) {
      _isUrgent = existingQuadrant.isUrgent;
      _isImportant = existingQuadrant.isImportant;
    } else if (widget.existingTask != null) {
      // Editing an inbox item - default to false (user must choose)
      _isUrgent = false;
      _isImportant = false;
    } else {
      // New task - default to urgent+important
      _isUrgent = true;
      _isImportant = true;
    }

    _dueDate = widget.existingTask?.dueDate;
    if (widget.existingTask?.hasDueTime ?? false) {
      _dueTime = TimeOfDay(
        hour: widget.existingTask!.dueTimeHour!,
        minute: widget.existingTask!.dueTimeMinute!,
      );
    }
    // Load existing subtasks (create copies to avoid modifying original)
    if (widget.existingTask?.hasSubtasks ?? false) {
      _subtasks = widget.existingTask!.subtasks
          .map((s) => s.copyWith())
          .toList();
    }
    // Load existing recurrence
    _recurrence = widget.existingTask?.recurrence ?? RecurrenceType.none;
    // Load existing tags
    _selectedTagIds = List<String>.from(widget.existingTask?.tagIds ?? []);
    // Load existing reminder offsets
    _selectedReminderOffsets = List<ReminderOffset>.from(
        widget.existingTask?.reminderOffsets ?? [ReminderOffset.atTime]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Quadrant get _selectedQuadrant =>
      QuadrantExtension.fromFlags(urgent: _isUrgent, important: _isImportant);

  void _handleSave() {
    final colors = context.appColors;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a task title'),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    widget.onSave(
      title,
      description.isNotEmpty ? description : null,
      _selectedQuadrant,
      _dueDate,
      _dueTime?.hour,
      _dueTime?.minute,
      _subtasks,
      _recurrence,
      _selectedTagIds,
      _selectedReminderOffsets,
    );
    Navigator.pop(context);
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.selectionClick();
    setState(() {
      _subtasks.add(Subtask(
        id: Subtask.generateId(),
        title: title,
      ));
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _subtasks[index] = _subtasks[index].copyWith(
        completed: !_subtasks[index].completed,
      );
    });
  }

  void _deleteSubtask(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  Future<void> _selectDueDate() async {
    final colors = context.appColors;
    HapticFeedback.selectionClick();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colors.isDark
                ? ColorScheme.dark(
                    primary: colors.surfaceLight,
                    onPrimary: colors.textPrimary,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.accent,
                    onPrimary: Colors.white,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _clearDueDate() {
    HapticFeedback.selectionClick();
    setState(() {
      _dueDate = null;
      _dueTime = null;
      _recurrence = RecurrenceType.none;
    });
  }

  Future<void> _selectDueTime() async {
    final colors = context.appColors;
    HapticFeedback.selectionClick();
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colors.isDark
                ? ColorScheme.dark(
                    primary: colors.surfaceLight,
                    onPrimary: colors.textPrimary,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.accent,
                    onPrimary: Colors.white,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  void _clearDueTime() {
    HapticFeedback.selectionClick();
    setState(() => _dueTime = null);
  }

  Color _getQuadrantColor(AppColorTheme colors) {
    switch (_selectedQuadrant) {
      case Quadrant.urgentImportant:
        return colors.urgentImportant;
      case Quadrant.notUrgentImportant:
        return colors.notUrgentImportant;
      case Quadrant.urgentNotImportant:
        return colors.urgentNotImportant;
      case Quadrant.notUrgentNotImportant:
        return colors.notUrgentNotImportant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _isEditing ? 'Edit Task' : 'New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Title input
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                prefixIcon: Icon(Icons.title_rounded, color: colors.textSecondary),
                suffixIcon: SpeechService().isAvailable
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: VoiceInputButton(
                          compact: true,
                          onResult: (text) {
                            final currentText = _titleController.text;
                            if (currentText.isEmpty) {
                              _titleController.text = text;
                            } else {
                              _titleController.text = '$currentText $text';
                            }
                            _titleController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _titleController.text.length),
                            );
                          },
                          onError: (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: colors.error,
                              ),
                            );
                          },
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Description input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add details (optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: colors.textSecondary),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Priority toggles
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    label: 'Urgent',
                    isSelected: _isUrgent,
                    colors: colors,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isUrgent = !_isUrgent);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToggleButton(
                    label: 'Important',
                    isSelected: _isImportant,
                    colors: colors,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isImportant = !_isImportant);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildQuadrantIndicator(colors),
            const SizedBox(height: 24),

            // Tags
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TagPicker(
              availableTags: widget.availableTags,
              selectedTagIds: _selectedTagIds,
              onTagsChanged: (tagIds) {
                setState(() => _selectedTagIds = tagIds);
              },
              onCreateTag: widget.onCreateTag,
            ),
            const SizedBox(height: 24),

            // Due date
            Text(
              'Due Date & Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 20, color: colors.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate != null
                                ? DateFormat('MMM d, yyyy').format(_dueDate!)
                                : 'No due date',
                            style: TextStyle(
                              fontSize: 16,
                              color: _dueDate != null
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearDueDate,
                    icon: const Icon(Icons.close_rounded),
                    color: colors.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.background,
                    ),
                  ),
                ],
              ],
            ),
            // Due time (only show if due date is set)
            if (_dueDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDueTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 20,
                              color: _dueTime != null
                                  ? colors.notUrgentImportant
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dueTime != null
                                  ? _dueTime!.format(context)
                                  : 'Add reminder time',
                              style: TextStyle(
                                fontSize: 16,
                                color: _dueTime != null
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                            if (_dueTime != null) ...[
                              const Spacer(),
                              Icon(
                                Icons.notifications_active_rounded,
                                size: 16,
                                color: colors.notUrgentImportant,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_dueTime != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearDueTime,
                      icon: const Icon(Icons.close_rounded),
                      color: colors.textSecondary,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.background,
                      ),
                    ),
                  ],
                ],
              ),
              // Reminder offset picker (only show if due time is set)
              if (_dueTime != null) ...[
                const SizedBox(height: 12),
                _buildReminderPicker(colors),
              ],
            ],

            // Recurrence picker (only show if due date is set)
            if (_dueDate != null) ...[
              const SizedBox(height: 24),
              Text(
                'Repeat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: RecurrenceType.values.map((type) {
                  final isSelected = _recurrence == type;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: type != RecurrenceType.monthly ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _recurrence = type);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.surfaceLight.withValues(alpha: 0.4)
                                : colors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? colors.surfaceLight
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Subtasks section
            Text(
              'Steps',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Existing subtasks list
            if (_subtasks.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _subtasks.length; i++)
                      _buildSubtaskItem(i, colors),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Add subtask input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a step...',
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.add_rounded,
                        color: colors.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  color: colors.textPrimary,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceLight.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getQuadrantColor(colors),
                  foregroundColor: colors.isDark ? colors.textPrimary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Add Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required AppColorTheme colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.surfaceLight.withValues(alpha: 0.4)
              : colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.surfaceLight : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: isSelected ? colors.textPrimary : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantIndicator(AppColorTheme colors) {
    final quadrantColor = _getQuadrantColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: quadrantColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: quadrantColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedQuadrant.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: quadrantColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderPicker(AppColorTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 18,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Remind me',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReminderOffset.values.map((offset) {
            final isSelected = _selectedReminderOffsets.contains(offset);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected) {
                    _selectedReminderOffsets.remove(offset);
                  } else {
                    _selectedReminderOffsets.add(offset);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.notUrgentImportant.withValues(alpha: 0.2)
                      : colors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colors.notUrgentImportant
                        : colors.surfaceLight,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: colors.notUrgentImportant,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      offset.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? colors.notUrgentImportant
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubtaskItem(int index, AppColorTheme colors) {
    final subtask = _subtasks[index];
    final isFirst = index == 0;
    final isLast = index == _subtasks.length - 1;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colors.surfaceLight.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            // Checkbox
            IconButton(
              onPressed: () => _toggleSubtask(index),
              icon: Icon(
                subtask.completed
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
                color: subtask.completed
                    ? colors.success
                    : colors.textSecondary,
              ),
              splashRadius: 20,
            ),
            // Title
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 15,
                  color: subtask.completed
                      ? colors.textSecondary
                      : colors.textPrimary,
                  decoration:
                      subtask.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Delete button
            IconButton(
              onPressed: () => _deleteSubtask(index),
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: colors.textSecondary,
              ),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
