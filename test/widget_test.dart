import 'package:flutter_test/flutter_test.dart';
import 'package:quadrant/main.dart';
import 'package:quadrant/theme/app_theme.dart';

void main() {
  testWidgets('App loads and shows Tasks title', (WidgetTester tester) async {
    await tester.pumpWidget(TaskMatrixApp(
      initialTheme: AppThemes.oliveDark,
      isOnboardingCompleted: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
  });
}
