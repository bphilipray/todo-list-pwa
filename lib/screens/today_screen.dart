import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';

enum TodayTab { today, upcoming, all }

class TodayScreen extends StatefulWidget {
  final List<Task> tasks;
  final List<Tag> tags;
  final TaskRepository repository;
  final Function(Task) onToggleComplete;
  final Function({Task? existingTask}) onEdit;
  final Function(Task)? onViewDetails;
  final Function(Task) onDelete;
  final Function(Task) onToggleUrgent;
  final Function(Task) onToggleImportant;
  final VoidCallback onOpenDrawer;

  const TodayScreen({
    super.key,
    required this.tasks,
    required this.tags,
    required this.repository,
    required this.onToggleComplete,
    required this.onEdit,
    this.onViewDetails,
    required this.onDelete,
    required this.onToggleUrgent,
    required this.onToggleImportant,
    required this.onOpenDrawer,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TodayTab _currentTab = TodayTab.today;

  List<Task> get _overdueTasks => widget.repository.getOverdueTasks(widget.tasks);
  List<Task> get _todayTasks => widget.repository.getTodayTasks(widget.tasks);
  List<Task> get _upcomingTasks => widget.repository.getUpcomingTasks(widget.tasks);
  List<Task> get _allScheduledTasks => widget.repository.getScheduledTasks(widget.tasks);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.onOpenDrawer,
          tooltip: 'Open navigation menu',
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(colors),

          // Content
          Expanded(
            child: _buildContent(colors),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, MMM d');
    return formatter.format(now);
  }

  Widget _buildTabBar(AppColorTheme colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TodayTab.values.map((tab) {
          final isSelected = _currentTab == tab;
          final count = _getTabCount(tab);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.surfaceLight.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getTabLabel(tab),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTabColor(tab, colors).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getTabColor(tab, colors),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTabLabel(TodayTab tab) {
    switch (tab) {
      case TodayTab.today:
        return 'Today';
      case TodayTab.upcoming:
        return 'Upcoming';
      case TodayTab.all:
        return 'All';
    }
  }

  int _getTabCount(TodayTab tab) {
    switch (tab) {
      case TodayTab.today:
        return _overdueTasks.length + _todayTasks.length;
      case TodayTab.upcoming:
        return _upcomingTasks.length;
      case TodayTab.all:
        return _allScheduledTasks.where((t) => !t.completed).length;
    }
  }

  Color _getTabColor(TodayTab tab, AppColorTheme colors) {
    switch (tab) {
      case TodayTab.today:
        return _overdueTasks.isNotEmpty
            ? colors.error
            : colors.notUrgentImportant;
      case TodayTab.upcoming:
        return colors.notUrgentImportant;
      case TodayTab.all:
        return colors.textSecondary;
    }
  }

  Widget _buildContent(AppColorTheme colors) {
    switch (_currentTab) {
      case TodayTab.today:
        return _buildTodayContent(colors);
      case TodayTab.upcoming:
        return _buildUpcomingContent(colors);
      case TodayTab.all:
        return _buildAllContent(colors);
    }
  }

  Widget _buildTodayContent(AppColorTheme colors) {
    final overdue = widget.repository.sortTasks(_overdueTasks);
    final today = widget.repository.sortTasks(_todayTasks);

    if (overdue.isEmpty && today.isEmpty) {
      return EmptyStates.noTasksToday(colors, onAddTask: () => widget.onEdit(existingTask: null));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Overdue section
        if (overdue.isNotEmpty) ...[
          _buildSectionHeader(
            'Overdue',
            overdue.length,
            colors.error,
            colors,
          ),
          ...overdue.map((task) => _buildTaskTile(task)),
        ],

        // Today section
        if (today.isNotEmpty) ...[
          _buildSectionHeader(
            'Due Today',
            today.length,
            colors.warning,
            colors,
          ),
          ...today.map((task) => _buildTaskTile(task)),
        ],
      ],
    );
  }

  Widget _buildUpcomingContent(AppColorTheme colors) {
    final upcoming = widget.repository.sortTasks(_upcomingTasks);

    if (upcoming.isEmpty) {
      return EmptyStates.noUpcomingTasks(colors, onAddTask: () => widget.onEdit(existingTask: null));
    }

    // Group by date
    final grouped = widget.repository.groupTasksByDate(upcoming);
    final sortedDates = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final date in sortedDates) ...[
          _buildDateHeader(date, colors),
          ...grouped[date]!.map((task) => _buildTaskTile(task)),
        ],
      ],
    );
  }

  Widget _buildAllContent(AppColorTheme colors) {
    final all = widget.repository.sortTasks(_allScheduledTasks);
    final active = all.where((t) => !t.completed).toList();
    final completed = all.where((t) => t.completed).toList();

    if (all.isEmpty) {
      return EmptyStates.noScheduledTasks(colors, onAddTask: () => widget.onEdit(existingTask: null));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (active.isNotEmpty) ...[
          _buildSectionHeader('Active', active.length, colors.notUrgentImportant, colors),
          ...active.map((task) => _buildTaskTile(task)),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader('Completed', completed.length, colors.success, colors),
          ...completed.map((task) => _buildTaskTile(task)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, AppColorTheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, AppColorTheme colors) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == DateTime(tomorrow.year, tomorrow.month, tomorrow.day)) {
      label = 'Tomorrow';
    } else {
      label = DateFormat('EEEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return TaskTile(
      task: task,
      allTags: widget.tags,
      onToggleComplete: () => widget.onToggleComplete(task),
      onEdit: () => widget.onEdit(existingTask: task),
      onViewDetails: widget.onViewDetails != null
          ? () => widget.onViewDetails!(task)
          : null,
      onDelete: () => widget.onDelete(task),
      onToggleUrgent: () => widget.onToggleUrgent(task),
      onToggleImportant: () => widget.onToggleImportant(task),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorTheme colors,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
