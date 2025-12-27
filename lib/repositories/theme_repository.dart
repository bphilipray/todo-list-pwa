import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeRepository {
  static const String _themeKey = 'selected_theme_id';

  Future<AppColorTheme> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(_themeKey);

    if (themeId == null) {
      return AppThemes.oliveDark;
    }

    return AppThemes.getById(themeId);
  }

  Future<void> saveTheme(AppColorTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.id);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}
