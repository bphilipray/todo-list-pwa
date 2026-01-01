import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showIllustration;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onActionPressed,
    this.showIllustration = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with subtle pulse
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              onEnd: () {},
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surfaceLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: colors.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),

            // Optional action button
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionText!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accent,
                  side: BorderSide(color: colors.accent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specialized empty states for common scenarios
class EmptyStates {
  static Widget noTasksToday(AppColorTheme colors, {VoidCallback? onAddTask}) {
    return EmptyState(
      icon: Icons.wb_sunny_rounded,
      title: 'All clear for today!',
      subtitle: 'No tasks due today.\nRelax and enjoy your day! ☀️',
      actionText: 'Add a Task',
      onActionPressed: onAddTask,
    );
  }

  static Widget noUpcomingTasks(AppColorTheme colors, {VoidCallback? onAddTask}) {
    return EmptyState(
      icon: Icons.event_available_rounded,
      title: 'No upcoming tasks',
      subtitle: 'Nothing scheduled for the next 7 days.\nYou\'re all caught up!',
      actionText: 'Schedule a Task',
      onActionPressed: onAddTask,
    );
  }

  static Widget noScheduledTasks(AppColorTheme colors, {VoidCallback? onAddTask}) {
    return EmptyState(
      icon: Icons.calendar_today_rounded,
      title: 'No scheduled tasks',
      subtitle: 'Tasks with due dates will appear here.\nStay organized by setting deadlines!',
      actionText: 'Add Task with Due Date',
      onActionPressed: onAddTask,
    );
  }

  static Widget emptyInbox(AppColorTheme colors) {
    return EmptyState(
      icon: Icons.inbox_rounded,
      title: 'Inbox is empty',
      subtitle: 'Capture thoughts and ideas quickly here.\nProcess them into your matrix later!',
    );
  }

  static Widget emptyQuadrant(
    AppColorTheme colors,
    String quadrantName,
    String description, {
    VoidCallback? onAddTask,
  }) {
    IconData icon;
    switch (quadrantName) {
      case 'Do First':
        icon = Icons.flash_on_rounded;
        break;
      case 'Schedule':
        icon = Icons.event_note_rounded;
        break;
      case 'Delegate':
        icon = Icons.people_rounded;
        break;
      case 'Drop':
        icon = Icons.delete_outline_rounded;
        break;
      default:
        icon = Icons.task_rounded;
    }

    return EmptyState(
      icon: icon,
      title: 'No "$quadrantName" tasks',
      subtitle: description,
      actionText: 'Add Task',
      onActionPressed: onAddTask,
    );
  }

  static Widget noSearchResults(AppColorTheme colors, String query) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: 'No tasks match "$query".\nTry different keywords or check spelling.',
    );
  }

  static Widget noTags(AppColorTheme colors, {VoidCallback? onCreateTag}) {
    return EmptyState(
      icon: Icons.label_outline_rounded,
      title: 'No tags yet',
      subtitle: 'Create tags to organize your tasks.\nColor-code projects, contexts, or priorities!',
      actionText: 'Create Tag',
      onActionPressed: onCreateTag,
    );
  }
}
