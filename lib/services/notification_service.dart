import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/task.dart';
import '../models/notification_sound.dart';
import '../repositories/notification_sound_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSoundRepository _soundRepository = NotificationSoundRepository();

  bool _isInitialized = false;
  NotificationSound _currentSound = NotificationSound.alarm;

  // Alarm-style notification channel
  static const String _alarmChannelId = 'task_alarms';
  static const String _alarmChannelName = 'Task Alarms';
  static const String _alarmChannelDescription =
      'Alarm-style notifications for task due times';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load saved notification sound
    _currentSound = await _soundRepository.loadSound();

    // Initialize timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the alarm notification channel on Android
    await _createAlarmChannel();

    _isInitialized = true;
  }

  Future<void> _createAlarmChannel() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description: _alarmChannelDescription,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'), // Default channel sound
        enableVibration: true,
        enableLights: true,
        // Use alarm audio attributes for louder sound
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to task
  }

  Future<bool> requestPermissions() async {
    // Request Android permissions
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Request notification permission (Android 13+)
      final notificationGranted = await androidPlugin.requestNotificationsPermission();

      // Check if exact alarms can be scheduled (Android 12+)
      // Note: On Android 14+, USE_EXACT_ALARM doesn't require user permission
      // but SCHEDULE_EXACT_ALARM does
      final canScheduleExact = await androidPlugin.canScheduleExactNotifications() ?? false;

      if (!canScheduleExact) {
        // Try to request exact alarm permission - this opens settings on some devices
        await androidPlugin.requestExactAlarmsPermission();
      }

      return notificationGranted ?? false;
    }

    // Request iOS permissions
    final iosPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Check if exact alarms can be scheduled
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS doesn't have this restriction
  }

  Future<void> scheduleTaskNotification(Task task) async {
    // First, cancel all existing notifications for this task
    await cancelTaskNotifications(task.id);

    if (task.completed) {
      print('⏰ NotificationService: Task "${task.title}" is completed, skipping notification');
      return;
    }

    final scheduledTime = task.scheduledDateTime;
    if (scheduledTime == null) {
      print('⏰ NotificationService: Task "${task.title}" has no due date/time, skipping notification');
      return;
    }

    if (task.reminderOffsets.isEmpty) {
      print('⏰ NotificationService: Task "${task.title}" has no reminder offsets, skipping notification');
      return;
    }

    final quadrantLabel = task.quadrant?.label ?? 'Inbox';
    final isUrgent = task.quadrant?.isUrgent ?? false;

    print('⏰ NotificationService: Scheduling ${task.reminderOffsets.length} notification(s) for task "${task.title}"');
    print('   Due: $scheduledTime');
    print('   Quadrant: $quadrantLabel');

    // Schedule a notification for each reminder offset
    for (final offset in task.reminderOffsets) {
      final reminderTime = scheduledTime.subtract(offset.duration);

      // Don't schedule if the reminder time has passed
      if (reminderTime.isBefore(DateTime.now())) {
        print('   ⏰ Skipping ${offset.label} - time has passed ($reminderTime)');
        continue;
      }

      final tzScheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

      // Use unique notification id: task id hash + offset index
      final notificationId = task.id.hashCode + offset.index;

      // Create alarm-style notification details for Android
      final androidDetails = AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        // Alarm-style enhancements
        fullScreenIntent: true, // Wake screen when locked
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true, // Dismiss when tapped
        ongoing: false, // Not persistent (user can swipe away)
        // Sound and vibration - use selected sound
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_currentSound.resourceName),
        enableVibration: true,
        vibrationPattern: isUrgent
            ? Int64List.fromList([0, 500, 200, 500, 200, 500]) // Urgent: longer pattern
            : Int64List.fromList([0, 400, 200, 400]), // Normal pattern
        // Visual enhancements
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 100, 100),
        ledOnMs: 1000,
        ledOffMs: 500,
        // Additional info
        ticker: 'Task Due: ${task.title}',
        subText: quadrantLabel,
      );

      // iOS critical alert for alarm-style
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Build notification title based on reminder offset
      final String notificationTitle;
      if (offset == ReminderOffset.atTime) {
        notificationTitle = '⏰ Task Due: $quadrantLabel';
      } else {
        notificationTitle = '⏰ Reminder: ${offset.label}';
      }

      // Check if we can use exact scheduling
      final canUseExact = await canScheduleExactAlarms();

      print('   ✅ Scheduling: ${offset.label} at $reminderTime (ID: $notificationId, Exact: $canUseExact)');

      await _notifications.zonedSchedule(
        notificationId,
        notificationTitle,
        task.title,
        tzScheduledTime,
        details,
        // Use exact if available, otherwise fall back to inexact
        androidScheduleMode: canUseExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }

    print('⏰ NotificationService: Successfully scheduled notifications for "${task.title}"');
  }

  /// Cancel all notifications for a specific task
  Future<void> cancelTaskNotifications(String taskId) async {
    // Cancel notification for each possible offset
    for (final offset in ReminderOffset.values) {
      await _notifications.cancel(taskId.hashCode + offset.index);
    }
  }

  Future<void> cancelNotification(String taskId) async {
    await cancelTaskNotifications(taskId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> rescheduleAllNotifications(List<Task> tasks) async {
    await cancelAllNotifications();
    for (final task in tasks) {
      if (!task.completed && task.scheduledDateTime != null) {
        await scheduleTaskNotification(task);
      }
    }
  }

  /// Change the notification sound (call this when user changes preference)
  Future<void> setNotificationSound(NotificationSound sound) async {
    _currentSound = sound;
    await _soundRepository.saveSound(sound);
  }

  /// Get current notification sound
  NotificationSound get currentSound => _currentSound;

  // Show an immediate test notification (for debugging)
  Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_currentSound.resourceName),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '⏰ Test Alarm',
      'This is a test alarm notification',
      details,
    );
  }

  /// Preview a specific notification sound
  Future<void> previewSound(NotificationSound sound) async {
    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound.resourceName),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Use a fixed ID for preview notifications
      '🔔 Sound Preview',
      sound.label,
      details,
    );
  }
}
