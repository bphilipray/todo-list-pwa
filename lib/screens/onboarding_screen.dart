import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  /// If true, shows Skip button (when accessed from Settings)
  final bool fromSettings;

  /// Called when onboarding is completed or skipped
  /// Passes the optional first task title if user entered one
  final void Function(String? firstTaskTitle) onComplete;

  const OnboardingScreen({
    super.key,
    required this.fromSettings,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _firstTaskController = TextEditingController();

  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    _firstTaskController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    final firstTask = _firstTaskController.text.trim();
    widget.onComplete(firstTask.isEmpty ? null : firstTask);
  }

  void _skip() {
    HapticFeedback.lightImpact();
    widget.onComplete(null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with Skip button (only from Settings)
            if (widget.fromSettings) _buildSkipButton(colors),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(colors),
                  _buildMatrixPage(colors),
                  _buildInboxPage(colors),
                  _buildTodayPage(colors),
                  _buildGetStartedPage(colors),
                ],
              ),
            ),

            // Bottom navigation
            _buildBottomNavigation(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton(dynamic colors) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: _skip,
          child: Text(
            'Skip',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? colors.accent : colors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Next / Get Started button
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: _currentPage == _totalPages - 1 ? _complete : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 1: Welcome
  Widget _buildWelcomePage(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.grid_view_rounded,
              size: 64,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Quadrant',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Capture. Prioritize. Execute.',
            style: TextStyle(
              fontSize: 18,
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Focus on what truly matters using the\nEisenhower Matrix method',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: The Matrix
  Widget _buildMatrixPage(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'The Eisenhower Matrix',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Organize tasks by urgency and importance',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // 2x2 Matrix grid
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuadrantBox(
                          colors.urgentImportant,
                          'Do First',
                          'Urgent & Important',
                          Icons.flash_on,
                        ),
                        const SizedBox(width: 8),
                        _buildQuadrantBox(
                          colors.notUrgentImportant,
                          'Schedule',
                          'Not Urgent & Important',
                          Icons.calendar_today,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuadrantBox(
                          colors.urgentNotImportant,
                          'Delegate',
                          'Urgent & Not Important',
                          Icons.person_add,
                        ),
                        const SizedBox(width: 8),
                        _buildQuadrantBox(
                          colors.notUrgentNotImportant,
                          'Drop',
                          'Not Urgent & Not Important',
                          Icons.delete_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantBox(Color color, String title, String subtitle, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 3: Inbox
  Widget _buildInboxPage(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Quick Capture',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Capture thoughts fast.\nPrioritize later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Preview of inbox input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.surfaceLight),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "What's on your mind?",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Use the Inbox to jot down ideas without\ndeciding their priority right away',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Page 4: Today
  Widget _buildTodayPage(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.today_rounded,
              size: 48,
              color: colors.warning,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Stay Focused',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'See what needs your attention today',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Preview of tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabPreview('Today', true, colors),
                _buildTabPreview('Upcoming', false, colors),
                _buildTabPreview('All', false, colors),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'View overdue tasks, today\'s schedule,\nand upcoming deadlines all in one place',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPreview(String label, bool isActive, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? colors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : colors.textSecondary,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // Page 5: Get Started
  Widget _buildGetStartedPage(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You\'re Ready!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore these features as you go',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Feature icons row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFeatureChip(Icons.repeat, 'Recurring', colors),
              _buildFeatureChip(Icons.notifications_outlined, 'Reminders', colors),
              _buildFeatureChip(Icons.label_outline, 'Tags', colors),
              _buildFeatureChip(Icons.palette_outlined, 'Themes', colors),
              _buildFeatureChip(Icons.cloud_outlined, 'Sync', colors),
            ],
          ),
          const SizedBox(height: 32),

          // Create first task input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.surfaceLight),
            ),
            child: TextField(
              controller: _firstTaskController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Create your first task (optional)',
                hintStyle: TextStyle(color: colors.textSecondary),
                border: InputBorder.none,
                icon: Icon(Icons.add_task, color: colors.accent),
              ),
              onSubmitted: (_) => _complete(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This will be added to your Inbox',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
