// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:passenger_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('passenger app explains authenticated access requirement', (
    tester,
  ) async {
    await tester.pumpWidget(const PassengerApp());

    expect(find.text('Find Your Kombi'), findsOneWidget);
    expect(
      find.textContaining('not currently provided for passengers'),
      findsOneWidget,
    );
    expect(find.text('SHOW KOMBIS ON MAP'), findsNothing);
  });
}
