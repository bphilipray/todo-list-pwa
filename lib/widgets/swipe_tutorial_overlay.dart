import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class SwipeTutorialOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismiss;

  const SwipeTutorialOverlay({
    super.key,
    required this.child,
    this.onDismiss,
  });

  @override
  State<SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();

  /// Show tutorial if user hasn't seen it before
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('swipe_tutorial_seen') ?? false);
  }

  /// Mark tutorial as seen
  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swipe_tutorial_seen', true);
  }
}

class _SwipeTutorialOverlayState extends State<SwipeTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await SwipeTutorialOverlay.markAsSeen();
    widget.onDismiss?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Stack(
          children: [
            // Dismissable background
            GestureDetector(
              onTap: _dismiss,
              child: Container(color: Colors.transparent),
            ),

            // Tutorial content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Swipe left instruction
                        _buildSwipeInstruction(
                          colors: colors,
                          icon: Icons.delete_outline_rounded,
                          iconColor: colors.error,
                          direction: 'Swipe Left',
                          action: 'Delete Task',
                          description: 'Remove the task permanently',
                        ),
                        const SizedBox(height: 24),

                        // Swipe right instruction
                        _buildSwipeInstruction(
                          colors: colors,
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: colors.success,
                          direction: 'Swipe Right',
                          action: 'Complete Task',
                          description: 'Mark as done (or reschedule if recurring)',
                        ),
                        const SizedBox(height: 24),

                        // Tap instruction
                        _buildSwipeInstruction(
                          colors: colors,
                          icon: Icons.edit_outlined,
                          iconColor: colors.notUrgentImportant,
                          direction: 'Tap',
                          action: 'Edit Task',
                          description: 'Change details, priority, or due date',
                        ),

                        const SizedBox(height: 40),

                        // Dismiss button
                        ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Got it!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap anywhere to dismiss',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeInstruction({
    required AppColorTheme colors,
    required IconData icon,
    required Color iconColor,
    required String direction,
    required String action,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.surfaceLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      direction,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: colors.textSecondary.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to easily show the tutorial
extension SwipeTutorialContext on BuildContext {
  Future<void> showSwipeTutorialIfNeeded() async {
    if (await SwipeTutorialOverlay.shouldShow()) {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500)); // Delay for better UX

      if (!mounted) return;

      await showDialog(
        context: this,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        builder: (context) => const SwipeTutorialOverlay(
          child: SizedBox.shrink(),
        ),
      );
    }
  }
}
