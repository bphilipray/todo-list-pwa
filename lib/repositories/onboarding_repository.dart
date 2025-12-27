import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const String _completedKey = 'onboarding_completed';

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// Reset onboarding flag (for "View Tutorial" from Settings)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
