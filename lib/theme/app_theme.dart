import 'package:flutter/material.dart';

/// Legacy static colors for backward compatibility
/// These are the Olive Dark theme colors - used in places without BuildContext
class AppColors {
  static const Color background = Color(0xFF646049);
  static const Color surface = Color(0xFF4a4736);
  static const Color surfaceLight = Color(0xFF7d7a63);
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFFA8A48F);
  static const Color urgentImportant = Color(0xFFC4785A);
  static const Color notUrgentImportant = Color(0xFF7A9E8C);
  static const Color urgentNotImportant = Color(0xFFC4A85A);
  static const Color notUrgentNotImportant = Color(0xFF8A8775);
  static const Color success = Color(0xFF7A9E8C);
  static const Color warning = Color(0xFFC4A85A);
  static const Color error = Color(0xFFC4785A);
}

/// Represents a complete color theme for the app
class AppColorTheme {
  final String id;
  final String name;
  final bool isDark;

  // Core colors
  final Color background;
  final Color surface;
  final Color surfaceLight;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;

  // Quadrant accent colors
  final Color urgentImportant;
  final Color notUrgentImportant;
  final Color urgentNotImportant;
  final Color notUrgentNotImportant;

  // Status colors
  final Color success;
  final Color warning;
  final Color error;

  // Accent/Primary color (for FAB, selections, etc.)
  final Color accent;

  const AppColorTheme({
    required this.id,
    required this.name,
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.urgentImportant,
    required this.notUrgentImportant,
    required this.urgentNotImportant,
    required this.notUrgentNotImportant,
    required this.success,
    required this.warning,
    required this.error,
    required this.accent,
  });
}

/// All available themes
class AppThemes {
  static const List<AppColorTheme> all = [
    oliveDark,
    midnight,
    ocean,
    sunset,
    forest,
    rose,
    monochrome,
    lightClassic,
    dracula,
    catppuccinLatte,
  ];

  static AppColorTheme getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => oliveDark,
    );
  }

  // ============================================
  // OLIVE DARK (Original/Default)
  // ============================================
  static const oliveDark = AppColorTheme(
    id: 'olive_dark',
    name: 'Olive Dark',
    isDark: true,
    background: Color(0xFF646049),
    surface: Color(0xFF4a4736),
    surfaceLight: Color(0xFF7d7a63),
    textPrimary: Color(0xFFF5F5F0),
    textSecondary: Color(0xFFA8A48F),
    urgentImportant: Color(0xFFC4785A),
    notUrgentImportant: Color(0xFF7A9E8C),
    urgentNotImportant: Color(0xFFC4A85A),
    notUrgentNotImportant: Color(0xFF8A8775),
    success: Color(0xFF7A9E8C),
    warning: Color(0xFFC4A85A),
    error: Color(0xFFC4785A),
    accent: Color(0xFF7A9E8C),
  );

  // ============================================
  // MIDNIGHT - Deep blues, modern
  // ============================================
  static const midnight = AppColorTheme(
    id: 'midnight',
    name: 'Midnight',
    isDark: true,
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceLight: Color(0xFF334155),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    urgentImportant: Color(0xFFF87171),
    notUrgentImportant: Color(0xFF60A5FA),
    urgentNotImportant: Color(0xFFFBBF24),
    notUrgentNotImportant: Color(0xFF6B7280),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    accent: Color(0xFF60A5FA),
  );

  // ============================================
  // OCEAN - Teals, aquas, calming
  // ============================================
  static const ocean = AppColorTheme(
    id: 'ocean',
    name: 'Ocean',
    isDark: true,
    background: Color(0xFF0C1821),
    surface: Color(0xFF1B2838),
    surfaceLight: Color(0xFF2A4158),
    textPrimary: Color(0xFFE0F7FA),
    textSecondary: Color(0xFF80CBC4),
    urgentImportant: Color(0xFFFF8A65),
    notUrgentImportant: Color(0xFF4DD0E1),
    urgentNotImportant: Color(0xFFFFD54F),
    notUrgentNotImportant: Color(0xFF607D8B),
    success: Color(0xFF4DD0E1),
    warning: Color(0xFFFFD54F),
    error: Color(0xFFFF8A65),
    accent: Color(0xFF26C6DA),
  );

  // ============================================
  // SUNSET - Warm oranges, corals
  // ============================================
  static const sunset = AppColorTheme(
    id: 'sunset',
    name: 'Sunset',
    isDark: true,
    background: Color(0xFF1A1423),
    surface: Color(0xFF2D1F3D),
    surfaceLight: Color(0xFF4A3558),
    textPrimary: Color(0xFFFFF5F5),
    textSecondary: Color(0xFFD4A5A5),
    urgentImportant: Color(0xFFFF6B6B),
    notUrgentImportant: Color(0xFFFFB347),
    urgentNotImportant: Color(0xFFFFD93D),
    notUrgentNotImportant: Color(0xFF8B7E74),
    success: Color(0xFF6BCB77),
    warning: Color(0xFFFFD93D),
    error: Color(0xFFFF6B6B),
    accent: Color(0xFFFF8E53),
  );

  // ============================================
  // FOREST - Natural greens, earth tones
  // ============================================
  static const forest = AppColorTheme(
    id: 'forest',
    name: 'Forest',
    isDark: true,
    background: Color(0xFF1A2F1A),
    surface: Color(0xFF2D4A2D),
    surfaceLight: Color(0xFF3D5C3D),
    textPrimary: Color(0xFFF0F5F0),
    textSecondary: Color(0xFFA8C5A8),
    urgentImportant: Color(0xFFE57373),
    notUrgentImportant: Color(0xFF81C784),
    urgentNotImportant: Color(0xFFFFB74D),
    notUrgentNotImportant: Color(0xFF8D9D8D),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFE57373),
    accent: Color(0xFF66BB6A),
  );

  // ============================================
  // ROSE - Playful pinks (Light theme)
  // ============================================
  static const rose = AppColorTheme(
    id: 'rose',
    name: 'Rose',
    isDark: false,
    background: Color(0xFFFFF0F5),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFFFE4EC),
    textPrimary: Color(0xFF4A2C40),
    textSecondary: Color(0xFF8B6A7D),
    urgentImportant: Color(0xFFE91E63),
    notUrgentImportant: Color(0xFFEC407A),
    urgentNotImportant: Color(0xFFFF9800),
    notUrgentNotImportant: Color(0xFF9E8A93),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFF9800),
    error: Color(0xFFE91E63),
    accent: Color(0xFFEC407A),
  );

  // ============================================
  // MONOCHROME - Minimal grays
  // ============================================
  static const monochrome = AppColorTheme(
    id: 'monochrome',
    name: 'Monochrome',
    isDark: true,
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceLight: Color(0xFF2D2D2D),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF9E9E9E),
    urgentImportant: Color(0xFFFF5252),
    notUrgentImportant: Color(0xFFB0B0B0),
    urgentNotImportant: Color(0xFFFFD740),
    notUrgentNotImportant: Color(0xFF757575),
    success: Color(0xFF69F0AE),
    warning: Color(0xFFFFD740),
    error: Color(0xFFFF5252),
    accent: Color(0xFFE0E0E0),
  );

  // ============================================
  // LIGHT CLASSIC - Clean white
  // ============================================
  static const lightClassic = AppColorTheme(
    id: 'light_classic',
    name: 'Light Classic',
    isDark: false,
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE8E8E8),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    urgentImportant: Color(0xFFD32F2F),
    notUrgentImportant: Color(0xFF1976D2),
    urgentNotImportant: Color(0xFFF57C00),
    notUrgentNotImportant: Color(0xFF757575),
    success: Color(0xFF388E3C),
    warning: Color(0xFFF57C00),
    error: Color(0xFFD32F2F),
    accent: Color(0xFF1976D2),
  );

  // ============================================
  // DRACULA - Popular dark theme
  // https://draculatheme.com/contribute
  // ============================================
  static const dracula = AppColorTheme(
    id: 'dracula',
    name: 'Dracula',
    isDark: true,
    background: Color(0xFF282A36),
    surface: Color(0xFF343746),
    surfaceLight: Color(0xFF44475A),
    textPrimary: Color(0xFFF8F8F2),
    textSecondary: Color(0xFF6272A4),
    urgentImportant: Color(0xFFFF5555),      // Red
    notUrgentImportant: Color(0xFF8BE9FD),   // Cyan
    urgentNotImportant: Color(0xFFFFB86C),   // Orange
    notUrgentNotImportant: Color(0xFF6272A4), // Comment
    success: Color(0xFF50FA7B),              // Green
    warning: Color(0xFFFFB86C),              // Orange
    error: Color(0xFFFF5555),                // Red
    accent: Color(0xFFBD93F9),               // Purple
  );

  // ============================================
  // CATPPUCCIN LATTE - Soothing pastels (Light)
  // https://catppuccin.com/palette
  // ============================================
  static const catppuccinLatte = AppColorTheme(
    id: 'catppuccin_latte',
    name: 'Catppuccin',
    isDark: false,
    background: Color(0xFFEFF1F5),           // Base
    surface: Color(0xFFE6E9EF),              // Mantle
    surfaceLight: Color(0xFFCCD0DA),         // Surface0
    textPrimary: Color(0xFF4C4F69),          // Text
    textSecondary: Color(0xFF6C6F85),        // Subtext0
    urgentImportant: Color(0xFFD20F39),      // Red
    notUrgentImportant: Color(0xFF1E66F5),   // Blue
    urgentNotImportant: Color(0xFFFE640B),   // Peach
    notUrgentNotImportant: Color(0xFF8C8FA1), // Overlay0
    success: Color(0xFF40A02B),              // Green
    warning: Color(0xFFDF8E1D),              // Yellow
    error: Color(0xFFD20F39),                // Red
    accent: Color(0xFF8839EF),               // Mauve
  );
}

/// Generates Flutter ThemeData from an AppColorTheme
class AppTheme {
  static ThemeData fromColorTheme(AppColorTheme colors) {
    final brightness = colors.isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        secondary: colors.notUrgentImportant,
        surface: colors.surface,
        error: colors.error,
        onPrimary: colors.isDark ? colors.textPrimary : Colors.white,
        onSecondary: colors.textPrimary,
        onSurface: colors.textPrimary,
        onError: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        // Use contrasting color based on accent brightness, not theme brightness
        foregroundColor: colors.accent.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        elevation: 4,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        hintStyle: TextStyle(color: colors.textSecondary),
        labelStyle: TextStyle(color: colors.textSecondary),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.success;
          }
          return colors.surfaceLight;
        }),
        checkColor: WidgetStateProperty.all(colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.surfaceLight,
        thickness: 0.5,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
      ),
      listTileTheme: ListTileThemeData(
        textColor: colors.textPrimary,
        iconColor: colors.textSecondary,
      ),
      iconTheme: IconThemeData(
        color: colors.textSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.surfaceLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent.withOpacity(0.5);
          }
          return colors.surface;
        }),
      ),
    );
  }

  // Legacy getter for backward compatibility during migration
  static ThemeData get darkTheme => fromColorTheme(AppThemes.oliveDark);
}

