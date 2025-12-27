import 'package:flutter/material.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_tile.dart';

class QuadrantSection extends StatefulWidget {
  final Quadrant quadrant;
  final List<Task> tasks;
  final List<Tag> allTags;
  final Function(Task) onToggleComplete;
  final Function(Task) onEdit;
  final Function(Task) onDelete;
  final Function(Task) onToggleUrgent;
  final Function(Task) onToggleImportant;

  const QuadrantSection({
    super.key,
    required this.quadrant,
    required this.tasks,
    required this.allTags,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleUrgent,
    required this.onToggleImportant,
  });

  @override
  State<QuadrantSection> createState() => _QuadrantSectionState();
}

class _QuadrantSectionState extends State<QuadrantSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_isExpanded) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAccentColor(AppColorTheme colors) {
    switch (widget.quadrant) {
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

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accentColor = _getAccentColor(colors);
    final activeCount = widget.tasks.where((t) => !t.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.quadrant.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.quadrant.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                RotationTransition(
                  turns: _iconRotation,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tasks
        AnimatedCrossFade(
          firstChild: _buildTaskList(colors),
          secondChild: const SizedBox(height: 0),
          crossFadeState:
              _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildTaskList(AppColorTheme colors) {
    if (widget.tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.surfaceLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 20,
                color: colors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'No tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: widget.tasks
          .map((task) => TaskTile(
                task: task,
                allTags: widget.allTags,
                onToggleComplete: () => widget.onToggleComplete(task),
                onEdit: () => widget.onEdit(task),
                onDelete: () => widget.onDelete(task),
                onToggleUrgent: () => widget.onToggleUrgent(task),
                onToggleImportant: () => widget.onToggleImportant(task),
              ))
          .toList(),
    );
  }
}
