import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final List<Tag> allTags;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleUrgent;
  final VoidCallback onToggleImportant;

  const TaskTile({
    super.key,
    required this.task,
    required this.allTags,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleUrgent,
    required this.onToggleImportant,
  });

  /// Get tags for this task
  List<Tag> get _taskTags {
    return allTags.where((t) => task.tagIds.contains(t.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dismissible(
      key: Key(task.id),
      background: _buildSwipeBackground(
        color: colors.success,
        icon: Icons.check_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: colors.error,
        icon: Icons.delete_rounded,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          onToggleComplete();
          return false;
        } else {
          return await _showDeleteConfirmation(context, colors);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCheckbox(colors),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(colors),
                      if (task.description != null &&
                          task.description!.isNotEmpty)
                        _buildDescription(colors),
                      if (_taskTags.isNotEmpty) _buildTagChips(colors),
                      if (task.dueDate != null) _buildDueDate(colors),
                      if (task.hasSubtasks) _buildSubtasksProgress(colors),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildPriorityToggles(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildCheckbox(AppColorTheme colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggleComplete();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: task.completed ? colors.success : Colors.transparent,
          border: Border.all(
            color: task.completed ? colors.success : colors.surfaceLight,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: task.completed
            ? Icon(Icons.check, size: 16, color: colors.textPrimary)
            : null,
      ),
    );
  }

  Widget _buildPriorityToggles(AppColorTheme colors) {
    // For inbox items (null quadrant), show both as inactive
    final isUrgent = task.quadrant?.isUrgent ?? false;
    final isImportant = task.quadrant?.isImportant ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPriorityPill(
          label: 'U',
          isActive: isUrgent,
          activeColor: colors.urgentImportant,
          colors: colors,
          onTap: () {
            HapticFeedback.selectionClick();
            onToggleUrgent();
          },
        ),
        const SizedBox(width: 4),
        _buildPriorityPill(
          label: 'I',
          isActive: isImportant,
          activeColor: colors.notUrgentImportant,
          colors: colors,
          onTap: () {
            HapticFeedback.selectionClick();
            onToggleImportant();
          },
        ),
      ],
    );
  }

  Widget _buildPriorityPill({
    required String label,
    required bool isActive,
    required Color activeColor,
    required AppColorTheme colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.3) : colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : colors.surfaceLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? activeColor : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(AppColorTheme colors) {
    return Text(
      task.title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: task.completed ? colors.textSecondary : colors.textPrimary,
        decoration: task.completed ? TextDecoration.lineThrough : null,
      ),
    );
  }

  Widget _buildDescription(AppColorTheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        task.description!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTagChips(AppColorTheme colors) {
    final tags = _taskTags;
    const maxVisible = 3;
    final visibleTags = tags.take(maxVisible).toList();
    final remaining = tags.length - maxVisible;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ...visibleTags.map((tag) => _buildTagChip(tag)),
          if (remaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.surfaceLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$remaining',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tag.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tag.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDate(AppColorTheme colors) {
    final statusColor = _getDueDateColor(colors);
    final statusText = _getDueDateText();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            task.hasDueTime ? Icons.notifications_active_rounded : Icons.calendar_today_rounded,
            size: 14,
            color: task.hasDueTime && !task.completed ? colors.notUrgentImportant : statusColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Recurrence indicator
          if (task.isRecurring) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.repeat_rounded,
              size: 14,
              color: colors.notUrgentImportant,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtasksProgress(AppColorTheme colors) {
    final completed = task.completedSubtasksCount;
    final total = task.totalSubtasksCount;
    final progress = task.subtasksProgress;
    final isAllCompleted = completed == total;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.surfaceLight.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAllCompleted
                      ? colors.success
                      : colors.notUrgentImportant,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Count text
          Text(
            '$completed/$total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isAllCompleted
                  ? colors.success
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(AppColorTheme colors) {
    if (task.completed) return colors.textSecondary;
    if (task.isOverdue) return colors.error;
    if (task.isDueToday) return colors.warning;
    if (task.isDueTomorrow) return colors.warning;
    return colors.textSecondary;
  }

  String _getDueDateText() {
    String dateText;
    if (task.isOverdue) {
      final days = task.daysUntilDue!.abs();
      dateText = 'Overdue by $days day${days > 1 ? 's' : ''}';
    } else if (task.isDueToday) {
      dateText = 'Due today';
    } else if (task.isDueTomorrow) {
      dateText = 'Due tomorrow';
    } else {
      dateText = DateFormat('MMM d').format(task.dueDate!);
    }

    // Add time if set
    if (task.hasDueTime) {
      final hour = task.dueTimeHour!;
      final minute = task.dueTimeMinute!;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final timeText = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      dateText = '$dateText at $timeText';
    }

    return dateText;
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, AppColorTheme colors) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.surface,
            title: const Text('Delete Task'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
