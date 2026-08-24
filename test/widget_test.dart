import 'package:flutter_test/flutter_test.dart';

import 'package:homiq/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that login screen contents are displayed.
    expect(find.text('Welcome to HomiQ'), findsOneWidget);
    expect(find.text('Login (Go to Dashboard)'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);
  });
}
