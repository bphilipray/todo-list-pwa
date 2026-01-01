enum NotificationSound {
  alarm('Alarm', 'alarm_sound', true),
  bell('Bell', 'notification_bell', true),
  chime('Chime', 'notification_chime', true),
  gentle('Gentle', 'notification_gentle', true),
  urgent('Urgent', 'notification_urgent', true),
  classic('Classic', 'notification_classic', true);

  final String label;
  final String fileName;
  final bool isAvailable; // Track which sounds actually exist

  const NotificationSound(this.label, this.fileName, this.isAvailable);

  /// Get NotificationSound from file name
  static NotificationSound fromFileName(String fileName) {
    return NotificationSound.values.firstWhere(
      (sound) => sound.fileName == fileName,
      orElse: () => NotificationSound.alarm,
    );
  }

  /// Get the raw resource name for Android (fallback to alarm_sound if not available)
  String get resourceName => isAvailable ? fileName : 'alarm_sound';

  /// Get only available sounds
  static List<NotificationSound> get availableSounds {
    return NotificationSound.values.where((s) => s.isAvailable).toList();
  }

  /// Get label with availability indicator
  String get displayLabel => isAvailable ? label : '$label (Coming Soon)';
}
