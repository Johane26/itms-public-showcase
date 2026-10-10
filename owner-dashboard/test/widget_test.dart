// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:http/testing.dart';
import 'package:owner_dashboard/main.dart';
import 'package:owner_dashboard/services/owner_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('owner dashboard requires owner sign in', (tester) async {
    final authService = OwnerAuthService(
      baseUrl: 'http://localhost',
      client: MockClient((_) async => throw StateError('Unexpected request')),
    );
    await tester.pumpWidget(OwnerDashboardApp(authService: authService));

    expect(find.text('Owner sign in'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    authService.dispose();
  });
}
