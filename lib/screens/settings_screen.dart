import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/calendar_service.dart';
import '../services/cloud_sync_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final List<Task> tasks;
  final List<Tag> tags;
  final VoidCallback onOpenDrawer;
  final Function(List<Task> tasks, List<Tag> tags) onRestoreBackup;
  final VoidCallback? onClearCalendarEventIds;
  final Function(List<Task> updatedTasks)? onCalendarSyncComplete;
  final Function(int deletedCount)? onDeleteCompletedTasks;
  final int? autoCleanupDays;
  final Function(int? days)? onAutoCleanupChanged;

  const SettingsScreen({
    super.key,
    required this.tasks,
    required this.tags,
    required this.onOpenDrawer,
    required this.onRestoreBackup,
    this.onClearCalendarEventIds,
    this.onCalendarSyncComplete,
    this.onDeleteCompletedTasks,
    this.autoCleanupDays,
    this.onAutoCleanupChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  final AuthService _authService = AuthService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final CalendarService _calendarService = CalendarService();

  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSigningIn = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Calendar sync state
  bool _calendarSyncEnabled = false;
  String? _selectedCalendarId;
  List<Calendar> _availableCalendars = [];
  bool _isLoadingCalendars = false;
  bool _isSyncingCalendar = false;

  int get _totalTasks => widget.tasks.length;
  int get _completedTasks => widget.tasks.where((t) => t.completed).length;
  int get _activeTasks => _totalTasks - _completedTasks;
  int get _inboxTasks => widget.tasks.where((t) => t.quadrant == null).length;

  AppColorTheme get _colors => context.appColors;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
    _loadCalendarSettings();
  }

  Future<void> _loadLastSyncTime() async {
    if (_authService.isSignedIn) {
      final time = await _cloudSyncService.getLastSyncTime();
      if (mounted) {
        setState(() => _lastSyncTime = time);
      }
    }
  }

  Future<void> _loadCalendarSettings() async {
    await _calendarService.initialize();
    final enabled = await _calendarService.isEnabled();
    final calendarId = await _calendarService.getSelectedCalendarId();

    if (enabled && _calendarService.hasPermissions) {
      final calendars = await _calendarService.getCalendars();
      if (mounted) {
        setState(() {
          _availableCalendars = calendars;
        });
      }
    }

    if (mounted) {
      setState(() {
        _calendarSyncEnabled = enabled;
        _selectedCalendarId = calendarId;
      });
    }
  }

  Future<void> _toggleCalendarSync(bool enabled) async {
    if (enabled) {
      // Request permissions first
      final granted = await _calendarService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Calendar permission required'),
              backgroundColor: _colors.error,
            ),
          );
        }
        return;
      }

      // Load available calendars
      setState(() => _isLoadingCalendars = true);
      final calendars = await _calendarService.getCalendars();
      if (mounted) {
        setState(() {
          _availableCalendars = calendars;
          _isLoadingCalendars = false;
        });
      }

      if (calendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No writable calendars found'),
              backgroundColor: _colors.error,
            ),
          );
        }
        return;
      }
    } else {
      // Ask user if they want to remove existing events
      final removeEvents = await _showRemoveEventsDialog();
      if (removeEvents == true) {
        final deleted = await _calendarService.deleteAllSyncedEvents(widget.tasks);
        widget.onClearCalendarEventIds?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed $deleted calendar events'),
              backgroundColor: _colors.success,
            ),
          );
        }
      }
    }

    await _calendarService.setEnabled(enabled);
    if (mounted) {
      setState(() {
        _calendarSyncEnabled = enabled;
        if (!enabled) {
          _selectedCalendarId = null;
        }
      });
    }
  }

  Future<bool?> _showRemoveEventsDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.surface,
        title: const Text('Remove Calendar Events?'),
        content: const Text(
          'Do you want to remove all synced events from your calendar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Events'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _colors.error),
            child: const Text('Remove Events'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCalendar(String? calendarId) async {
    await _calendarService.setSelectedCalendarId(calendarId);
    if (mounted) {
      setState(() {
        _selectedCalendarId = calendarId;
      });
    }
  }

  Future<void> _syncAllTasksToCalendar() async {
    if (_selectedCalendarId == null) return;

    setState(() => _isSyncingCalendar = true);

    try {
      final result = await _calendarService.syncAllTasks(widget.tasks);

      // Notify parent to update tasks with new calendarEventIds
      widget.onCalendarSyncComplete?.call(result.updatedTasks);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced ${result.synced} tasks${result.failed > 0 ? ', ${result.failed} failed' : ''}'),
            backgroundColor: result.failed > 0 ? _colors.warning : _colors.success,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingCalendar = false);
      }
    }
  }

  void _changeTheme(AppColorTheme theme) {
    TaskMatrixApp.of(context)?.setTheme(theme);
    HapticFeedback.selectionClick();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (mounted) {
        if (result != null) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signed in as ${result.user?.email}'),
              backgroundColor: _colors.success,
            ),
          );
          _loadLastSyncTime();
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: _colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.surface,
        title: const Text('Sign Out?'),
        content: const Text(
          'Your local data will be kept, but you won\'t be able to sync until you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _colors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        setState(() => _lastSyncTime = null);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Signed out'),
            backgroundColor: _colors.surface,
          ),
        );
      }
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      final result = await _cloudSyncService.sync(
        localTasks: widget.tasks,
        localTags: widget.tags,
      );

      if (!mounted) return;

      if (result.result.success) {
        HapticFeedback.mediumImpact();
        widget.onRestoreBackup(result.tasks, result.tags);
        _loadLastSyncTime();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced: ${result.result.tasksUploaded} tasks, ${result.result.tagsUploaded} tags',
            ),
            backgroundColor: _colors.success,
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.result.error ?? 'Sync failed'),
            backgroundColor: _colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final success = await _backupService.exportData(
        tasks: widget.tasks,
        tags: widget.tags,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Backup exported successfully' : 'Failed to export backup',
            ),
            backgroundColor: success ? _colors.success : _colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);

    try {
      final result = await _backupService.importData();

      if (!mounted) return;

      if (!result.success) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Import failed'),
            backgroundColor: _colors.error,
          ),
        );
        return;
      }

      final backup = result.data!;
      final summary = _backupService.getBackupSummary(backup);

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _colors.surface,
          title: const Text('Restore Backup?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will replace all your current data.',
                style: TextStyle(
                  color: _colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _colors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup contents:',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exported: ${_formatDate(backup.exportedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _colors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _colors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: _colors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current data will be permanently replaced',
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: _colors.accent,
              ),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        HapticFeedback.mediumImpact();
        widget.onRestoreBackup(backup.tasks, backup.tags);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup restored successfully'),
            backgroundColor: _colors.success,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.onOpenDrawer,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 12),
          _buildThemeCard(),

          const SizedBox(height: 24),

          // Cloud Sync Section
          _buildSectionHeader('Cloud Sync'),
          const SizedBox(height: 12),
          _buildCloudSyncCard(),

          const SizedBox(height: 24),

          // Calendar Sync Section
          _buildSectionHeader('Calendar Sync'),
          const SizedBox(height: 12),
          _buildCalendarSyncCard(),

          const SizedBox(height: 24),

          // Backup & Restore Section
          _buildSectionHeader('Local Backup'),
          const SizedBox(height: 12),
          _buildBackupCard(),

          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          const SizedBox(height: 12),
          _buildDataManagementCard(),

          const SizedBox(height: 24),

          // Statistics Section
          _buildSectionHeader('Statistics'),
          const SizedBox(height: 12),
          _buildStatsCard(),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          const SizedBox(height: 12),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _colors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeCard() {
    final currentTheme = TaskMatrixApp.of(context)?.currentTheme ?? AppThemes.oliveDark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _colors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: _colors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Current: ${currentTheme.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AppThemes.all.length,
              itemBuilder: (context, index) {
                final theme = AppThemes.all[index];
                final isSelected = theme.id == currentTheme.id;

                return _buildThemeTile(theme, isSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(AppColorTheme theme, bool isSelected) {
    return GestureDetector(
      onTap: () => _changeTheme(theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _colors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              // Color preview (top half)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.background,
                  ),
                  child: Stack(
                    children: [
                      // Accent color dot
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Quadrant color dots
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _colorDot(theme.urgentImportant),
                            _colorDot(theme.notUrgentImportant),
                            _colorDot(theme.urgentNotImportant),
                          ],
                        ),
                      ),
                      // Selected checkmark
                      if (isSelected)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _colors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: theme.isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Theme name (bottom)
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  color: theme.surface,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    theme.name,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCloudSyncCard() {
    final isSignedIn = _authService.isSignedIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Cloud Sync',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _colors.textPrimary,
                        ),
                      ),
                      Text(
                        isSignedIn
                            ? 'Signed in as ${_authService.email}'
                            : 'Sign in to sync across devices',
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSignedIn && _lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _colors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: _colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last synced: ${_formatDate(_lastSyncTime!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isSignedIn)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.sync_rounded,
                      label: 'Sync Now',
                      onPressed: _isSyncing ? null : _syncData,
                      isLoading: _isSyncing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      onPressed: _signOut,
                      isSecondary: true,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: _buildGoogleSignInButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isSigningIn ? null : _signInWithGoogle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSigningIn)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black54,
                  ),
                )
              else
                Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 24,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(width: 12),
              Text(
                _isSigningIn ? 'Signing in...' : 'Sign in with Google',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSyncCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Calendar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Sync tasks to your calendar',
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _calendarSyncEnabled,
                  onChanged: _toggleCalendarSync,
                  activeColor: _colors.accent,
                ),
              ],
            ),
            if (_calendarSyncEnabled) ...[
              const SizedBox(height: 16),
              // Calendar selector dropdown
              if (_isLoadingCalendars)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_availableCalendars.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _colors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCalendarId,
                      hint: Text(
                        'Select calendar',
                        style: TextStyle(color: _colors.textSecondary),
                      ),
                      isExpanded: true,
                      dropdownColor: _colors.surface,
                      items: _availableCalendars.map((cal) {
                        return DropdownMenuItem(
                          value: cal.id,
                          child: Text(
                            cal.name ?? 'Unknown Calendar',
                            style: TextStyle(color: _colors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: _selectCalendar,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.sync_rounded,
                    label: 'Sync All Tasks',
                    onPressed: _selectedCalendarId == null || _isSyncingCalendar
                        ? null
                        : _syncAllTasksToCalendar,
                    isLoading: _isSyncingCalendar,
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _colors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: _colors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No writable calendars found',
                          style: TextStyle(
                            fontSize: 13,
                            color: _colors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _colors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.backup_rounded,
                    color: _colors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local Backup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Export or restore your tasks and tags',
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.upload_rounded,
                    label: 'Export',
                    onPressed: _isExporting ? null : _exportData,
                    isLoading: _isExporting,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.download_rounded,
                    label: 'Import',
                    onPressed: _isImporting ? null : _importData,
                    isLoading: _isImporting,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    final completedCount = widget.tasks.where((t) => t.completed).length;
    final autoCleanupDays = widget.autoCleanupDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cleaning_services_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cleanup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _colors.textPrimary,
                        ),
                      ),
                      Text(
                        '$completedCount completed task${completedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Delete Completed Tasks button
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                icon: Icons.delete_sweep_rounded,
                label: 'Delete Completed Tasks',
                onPressed: completedCount > 0 ? _showDeleteCompletedDialog : null,
                isSecondary: true,
              ),
            ),
            const SizedBox(height: 16),
            // Auto-cleanup toggle and selector
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_delete_rounded,
                        size: 20,
                        color: _colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-delete completed tasks',
                          style: TextStyle(
                            fontSize: 14,
                            color: _colors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: autoCleanupDays != null,
                        onChanged: (enabled) {
                          if (enabled) {
                            widget.onAutoCleanupChanged?.call(7); // Default to 7 days
                          } else {
                            widget.onAutoCleanupChanged?.call(null);
                          }
                        },
                        activeColor: _colors.accent,
                      ),
                    ],
                  ),
                  if (autoCleanupDays != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Delete after:',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [7, 14, 30].map((days) {
                        final isSelected = autoCleanupDays == days;
                        return ChoiceChip(
                          label: Text('$days days'),
                          selected: isSelected,
                          onSelected: (_) {
                            widget.onAutoCleanupChanged?.call(days);
                            HapticFeedback.selectionClick();
                          },
                          selectedColor: _colors.accent,
                          backgroundColor: _colors.surface,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _colors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteCompletedDialog() async {
    final completedCount = widget.tasks.where((t) => t.completed).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.surface,
        title: const Text('Delete Completed Tasks?'),
        content: Text(
          'This will permanently delete $completedCount completed task${completedCount == 1 ? '' : 's'}. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDeleteCompletedTasks?.call(completedCount);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted $completedCount completed task${completedCount == 1 ? '' : 's'}'),
          backgroundColor: _colors.success,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isSecondary = false,
  }) {
    return Material(
      color: isSecondary
          ? _colors.surfaceLight.withOpacity(0.3)
          : _colors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _colors.textPrimary,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 20,
                  color: _colors.textPrimary,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Total Tasks',
                    value: '$_totalTasks',
                    icon: Icons.list_alt_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: _colors.surfaceLight.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Completed',
                    value: '$_completedTasks',
                    icon: Icons.check_circle_rounded,
                    color: _colors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: _colors.surfaceLight.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Active',
                    value: '$_activeTasks',
                    icon: Icons.pending_actions_rounded,
                    color: _colors.accent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: _colors.surfaceLight.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'In Inbox',
                    value: '$_inboxTasks',
                    icon: Icons.inbox_rounded,
                    color: _colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color ?? _colors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _colors.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: _colors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Matrix',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: _colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _colors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Prioritize what matters using the Eisenhower Matrix. Organize tasks by urgency and importance.',
                style: TextStyle(
                  fontSize: 14,
                  color: _colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // View Tutorial button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OnboardingScreen(
                      fromSettings: true,
                      onComplete: (_) => Navigator.of(context).pop(),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _colors.surfaceLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: _colors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View Tutorial',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Learn how to use Task Matrix',
                            style: TextStyle(
                              fontSize: 12,
                              color: _colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: _colors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
