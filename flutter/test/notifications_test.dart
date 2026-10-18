import 'package:buildtrack/screens/app_shell.dart';
import 'package:buildtrack/screens/notifications_screen.dart';
import 'package:buildtrack/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home bell opens the notifications modal', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: MaterialApp(home: const AppShell(onSignOut: _noopFuture)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byIcon(Ionicons.notifications_outline), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);

    await tester.tap(find.byIcon(Ionicons.notifications_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('All clear'), findsOneWidget);

    // Tapping the barrier dismisses the modal and returns to the shell.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Notifications'), findsNothing);
    expect(find.byIcon(Ionicons.notifications_outline), findsOneWidget);
  });

  testWidgets('notifications list renders the all-clear empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const MaterialApp(
          home: NotificationsList(items: [], onOpenTab: _noop),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('All clear'), findsOneWidget);
    expect(find.byIcon(Ionicons.notifications_off_outline), findsOneWidget);
  });

  testWidgets('buildNotifications derives items from live state data', (
    tester,
  ) async {
    final items = buildNotifications(AppState());

    expect(items, isEmpty);
  });
}

void _noop(int _) {}

Future<void> _noopFuture() async {}
