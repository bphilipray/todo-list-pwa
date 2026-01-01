import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskDetailSheet extends StatelessWidget {
  final Task task;
  final List<Tag> availableTags;
  final VoidCallback onEdit;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.availableTags,
    required this.onEdit,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context, colors),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildTitle(context, colors),
                  const SizedBox(height: 24),

                  // Description
                  if (task.description != null && task.description!.isNotEmpty)
                    _buildDescription(colors),

                  // Quadrant/Priority
                  if (task.quadrant != null) _buildQuadrant(colors),

                  // Due Date
                  if (task.dueDate != null) _buildDueDate(colors),

                  // Recurrence
                  if (task.recurrence != RecurrenceType.none)
                    _buildRecurrence(colors),

                  // Reminders
                  if (task.reminderOffsets.isNotEmpty) _buildReminders(colors),

                  // Tags
                  if (task.tagIds.isNotEmpty) _buildTags(colors),

                  // Subtasks
                  if (task.hasSubtasks) _buildSubtasks(colors),

                  // Created date
                  _buildCreatedDate(colors),
                ],
              ),
            ),
          ),

          // Action buttons
          _buildActionButtons(context, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.surfaceLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.article_outlined,
            color: colors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Task Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: colors.textSecondary,
            ),
            tooltip: 'Close details',
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, AppColorTheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Completion checkbox
        GestureDetector(
          onTap: () {
            onToggleComplete();
            Navigator.pop(context);
          },
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: task.completed ? colors.success : colors.textSecondary,
                width: 2,
              ),
              color: task.completed
                  ? colors.success
                  : Colors.transparent,
            ),
            child: task.completed
                ? Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colors.isDark ? colors.textPrimary : Colors.white,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),

        // Title text
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: task.completed
                  ? colors.textSecondary
                  : colors.textPrimary,
              decoration: task.completed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(AppColorTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Description', Icons.notes_rounded, colors),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.description!,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuadrant(AppColorTheme colors) {
    final quadrant = task.quadrant!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Priority', Icons.flag_rounded, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getQuadrantColor(quadrant, colors).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getQuadrantColor(quadrant, colors).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getQuadrantColor(quadrant, colors),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                quadrant.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _getQuadrantColor(quadrant, colors),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${quadrant.description}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDueDate(AppColorTheme colors) {
    final formatter = DateFormat('EEEE, MMM d, y');
    final dateStr = formatter.format(task.dueDate!);
    final timeStr = task.hasDueTime
        ? '${task.dueTimeHour!.toString().padLeft(2, '0')}:${task.dueTimeMinute!.toString().padLeft(2, '0')}'
        : null;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (task.isOverdue) {
      statusColor = colors.error;
      statusLabel = 'Overdue';
      statusIcon = Icons.error_outline_rounded;
    } else if (task.isDueToday) {
      statusColor = colors.warning;
      statusLabel = 'Due Today';
      statusIcon = Icons.today_rounded;
    } else if (task.isDueTomorrow) {
      statusColor = colors.notUrgentImportant;
      statusLabel = 'Due Tomorrow';
      statusIcon = Icons.event_rounded;
    } else {
      final days = task.daysUntilDue;
      statusColor = colors.textSecondary;
      statusLabel = days != null ? 'Due in $days days' : 'Scheduled';
      statusIcon = Icons.calendar_today_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Due Date', Icons.event_rounded, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (timeStr != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: colors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecurrence(AppColorTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Recurrence', Icons.repeat_rounded, colors),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.repeat_rounded,
                color: colors.accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                task.recurrence.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReminders(AppColorTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'Reminders',
          Icons.notifications_outlined,
          colors,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: task.reminderOffsets.map((offset) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.surfaceLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                offset.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTags(AppColorTheme colors) {
    final taskTags = availableTags
        .where((tag) => task.tagIds.contains(tag.id))
        .toList();

    if (taskTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Tags', Icons.label_outline_rounded, colors),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: taskTags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tag.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tag.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tag.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tag.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubtasks(AppColorTheme colors) {
    final completedCount = task.completedSubtasksCount;
    final totalCount = task.totalSubtasksCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('Subtasks', Icons.checklist_rounded, colors),
            const Spacer(),
            Text(
              '$completedCount / $totalCount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: task.subtasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subtask = entry.value;
              final isLast = index == task.subtasks.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: colors.surfaceLight.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: subtask.completed
                              ? colors.success
                              : colors.textSecondary.withOpacity(0.5),
                          width: 2,
                        ),
                        color: subtask.completed
                            ? colors.success
                            : Colors.transparent,
                      ),
                      child: subtask.completed
                          ? Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: colors.isDark
                                  ? colors.textPrimary
                                  : Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 15,
                          color: subtask.completed
                              ? colors.textSecondary
                              : colors.textPrimary,
                          decoration: subtask.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCreatedDate(AppColorTheme colors) {
    final formatter = DateFormat('MMM d, y • h:mm a');
    final createdStr = formatter.format(task.createdAt);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: colors.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            'Created $createdStr',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.surfaceLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Delete button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
              icon: Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Edit button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor:
                    colors.isDark ? colors.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    IconData icon,
    AppColorTheme colors,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Color _getQuadrantColor(Quadrant quadrant, AppColorTheme colors) {
    switch (quadrant) {
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
}
