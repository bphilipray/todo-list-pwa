import 'package:flutter/material.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../screens/main_screen.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final AppScreen currentScreen;
  final int inboxCount;
  final int todayCount;
  final List<Tag> tags;
  final List<Task> tasks;
  final String? selectedTagId;
  final Function(AppScreen) onNavigate;
  final Function(String?) onSelectTag;

  const AppDrawer({
    super.key,
    required this.currentScreen,
    required this.inboxCount,
    required this.todayCount,
    required this.tags,
    required this.tasks,
    required this.selectedTagId,
    required this.onNavigate,
    required this.onSelectTag,
  });

  int _getTaskCountForTag(String tagId) {
    return tasks.where((t) => t.tagIds.contains(tagId) && !t.completed).length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: colors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quadrant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Eisenhower Priority System',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.surfaceLight),

            const SizedBox(height: 16),

            // Navigation items
            _buildNavItem(
              context: context,
              icon: Icons.dashboard_rounded,
              label: 'Home',
              isSelected: currentScreen == AppScreen.home,
              onTap: () => onNavigate(AppScreen.home),
            ),

            _buildNavItem(
              context: context,
              icon: Icons.today_rounded,
              label: 'Today',
              isSelected: currentScreen == AppScreen.today,
              badge: todayCount > 0 ? todayCount : null,
              badgeColor: colors.warning,
              onTap: () => onNavigate(AppScreen.today),
            ),

            _buildNavItem(
              context: context,
              icon: Icons.inbox_rounded,
              label: 'Inbox',
              isSelected: currentScreen == AppScreen.inbox,
              badge: inboxCount > 0 ? inboxCount : null,
              onTap: () => onNavigate(AppScreen.inbox),
            ),

            _buildNavItem(
              context: context,
              icon: Icons.label_outline_rounded,
              label: 'Manage Tags',
              isSelected: currentScreen == AppScreen.tags,
              onTap: () => onNavigate(AppScreen.tags),
            ),

            _buildNavItem(
              context: context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              isSelected: currentScreen == AppScreen.settings,
              onTap: () => onNavigate(AppScreen.settings),
            ),

            // Tags section
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.surfaceLight),
              const SizedBox(height: 16),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'TAGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (selectedTagId != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          onSelectTag(null);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tag list
              ...tags.map((tag) => _buildTagItem(context, tag, colors)),
            ],

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Capture. Prioritize. Execute.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    int? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final effectiveBadgeColor = badgeColor ?? colors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? colors.accent.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? colors.accent
                      : colors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveBadgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: effectiveBadgeColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagItem(BuildContext context, Tag tag, AppColorTheme colors) {
    final isSelected = selectedTagId == tag.id;
    final count = _getTaskCountForTag(tag.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: isSelected
            ? tag.color.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            onSelectTag(isSelected ? null : tag.id);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tag.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Tag name
                Expanded(
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                // Count badge
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tag.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tag.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
