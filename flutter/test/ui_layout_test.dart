import 'package:buildtrack/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      body: Column(children: [SizedBox(height: 200, child: child)]),
    ),
  );

  testWidgets('ScreenHeader with an expanding trailing button lays out', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ScreenHeader(
          title: 'Projects',
          subtitle: '2 total · 1 active',
          trailing: AppButton(
            title: 'New Project',
            icon: Icons.add,
            expand: true,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('2 total · 1 active'), findsOneWidget);
  });

  testWidgets('ScreenHeader renders without a trailing widget', (tester) async {
    await tester.pumpWidget(wrap(const ScreenHeader(title: 'More')));

    expect(tester.takeException(), isNull);
  });

  testWidgets('ScreenHeader inside a bounded row keeps both children', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ScreenHeader(
          title: 'Tasks',
          trailing: const IconBadge(icon: Icons.search),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
