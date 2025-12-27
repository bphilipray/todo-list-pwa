import 'package:flutter_test/flutter_test.dart';
import 'package:task_matrix/main.dart';
import 'package:task_matrix/theme/app_theme.dart';

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
