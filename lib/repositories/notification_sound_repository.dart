import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_sound.dart';

class NotificationSoundRepository {
  static const String _soundKey = 'notification_sound';

  /// Load the saved notification sound preference
  Future<NotificationSound> loadSound() async {
    final prefs = await SharedPreferences.getInstance();
    final soundFileName = prefs.getString(_soundKey);

    if (soundFileName == null) {
      return NotificationSound.alarm; // Default
    }

    return NotificationSound.fromFileName(soundFileName);
  }

  /// Save the notification sound preference
  Future<void> saveSound(NotificationSound sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKey, sound.fileName);
  }
}
