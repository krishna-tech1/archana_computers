import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ArchanaComputersApp());

    // Verify that the login page is shown.
    expect(find.text('Service management system'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });
}
