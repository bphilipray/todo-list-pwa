import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'repositories/theme_repository.dart';
import 'repositories/onboarding_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService().initialize();

  // Load saved theme
  final themeRepository = ThemeRepository();
  final savedTheme = await themeRepository.loadTheme();

  // Check if onboarding is completed
  final onboardingRepository = OnboardingRepository();
  final isOnboardingCompleted = await onboardingRepository.isOnboardingCompleted();

  runApp(TaskMatrixApp(
    initialTheme: savedTheme,
    isOnboardingCompleted: isOnboardingCompleted,
  ));
}

class TaskMatrixApp extends StatefulWidget {
  final AppColorTheme initialTheme;
  final bool isOnboardingCompleted;

  const TaskMatrixApp({
    super.key,
    required this.initialTheme,
    required this.isOnboardingCompleted,
  });

  @override
  State<TaskMatrixApp> createState() => TaskMatrixAppState();

  /// Access the app state to change theme from anywhere
  static TaskMatrixAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<TaskMatrixAppState>();
  }
}

class TaskMatrixAppState extends State<TaskMatrixApp> {
  late AppColorTheme _currentTheme;
  final ThemeRepository _themeRepository = ThemeRepository();
  final OnboardingRepository _onboardingRepository = OnboardingRepository();

  late bool _isOnboardingCompleted;
  String? _firstTaskTitle;

  /// Global key for ScaffoldMessenger to handle snackbars across nested scaffolds
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  AppColorTheme get currentTheme => _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
    _isOnboardingCompleted = widget.isOnboardingCompleted;
    _updateSystemUI();
  }

  void _completeOnboarding(String? firstTaskTitle) async {
    await _onboardingRepository.markOnboardingCompleted();
    setState(() {
      _isOnboardingCompleted = true;
      _firstTaskTitle = firstTaskTitle;
    });
  }

  void setTheme(AppColorTheme theme) {
    setState(() {
      _currentTheme = theme;
    });
    _themeRepository.saveTheme(theme);
    _updateSystemUI();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          _currentTheme.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _currentTheme.background,
      systemNavigationBarIconBrightness:
          _currentTheme.isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      theme: _currentTheme,
      child: MaterialApp(
        title: 'Quadrant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fromColorTheme(_currentTheme),
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: _isOnboardingCompleted
            ? MainScreen(initialTaskTitle: _firstTaskTitle)
            : OnboardingScreen(
                fromSettings: false,
                onComplete: _completeOnboarding,
              ),
      ),
    );
  }
}

/// InheritedWidget to provide theme colors throughout the app
class ThemeProvider extends InheritedWidget {
  final AppColorTheme theme;

  const ThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  static AppColorTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    return provider?.theme ?? AppThemes.oliveDark;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return theme.id != oldWidget.theme.id;
  }
}

/// Extension to easily access theme colors from context
extension AppThemeContext on BuildContext {
  AppColorTheme get appColors => ThemeProvider.of(this);
}
