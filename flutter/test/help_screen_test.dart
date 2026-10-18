import 'package:buildtrack/screens/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Help & Support renders and FAQ tiles expand', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Talk to a human'), findsOneWidget);
    expect(find.text('How do I add a project?'), findsOneWidget);

    expect(find.textContaining('Open the Projects tab'), findsNothing);

    await tester.tap(find.text('How do I add a project?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Open the Projects tab'), findsOneWidget);

    await tester.tap(find.text('How do I add a project?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Open the Projects tab'), findsNothing);
  });
}
