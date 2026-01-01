enum NotificationSound {
  alarm('Alarm', 'alarm_sound'),
  bell('Bell', 'notification_bell'),
  chime('Chime', 'notification_chime'),
  gentle('Gentle', 'notification_gentle'),
  urgent('Urgent', 'notification_urgent'),
  classic('Classic', 'notification_classic');

  final String label;
  final String fileName;

  const NotificationSound(this.label, this.fileName);

  /// Get NotificationSound from file name
  static NotificationSound fromFileName(String fileName) {
    return NotificationSound.values.firstWhere(
      (sound) => sound.fileName == fileName,
      orElse: () => NotificationSound.alarm,
    );
  }

  /// Get the raw resource name for Android
  String get resourceName => fileName;
}
