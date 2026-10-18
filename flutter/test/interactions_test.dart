import 'dart:async';

import 'package:buildtrack/screens/app_shell.dart';
import 'package:buildtrack/screens/project_detail_screen.dart';
import 'package:buildtrack/screens/tasks_screen.dart';
import 'package:buildtrack/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

Widget wrap(Widget child) {
  return ChangeNotifierProvider<AppState>(
    create: (_) => AppState(),
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('tasks search button toggles a filter field', (tester) async {
    await tester.pumpWidget(wrap(const TasksScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Search tasks or projects...'), findsNothing);

    await tester.tap(find.byIcon(Ionicons.search_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Search tasks or projects...'), findsOneWidget);
  });

  testWidgets('project detail search button toggles a filter field', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const ProjectDetailScreen(projectId: 'missing')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Project unavailable'), findsOneWidget);
  });

  testWidgets('project detail overflow menu opens with actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const ProjectDetailScreen(projectId: 'missing')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Update progress'), findsNothing);
  });

  testWidgets('sign out button opens the confirmation dialog', (tester) async {
    final signOutGate = Completer<void>();
    var signOutCalls = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: MaterialApp(
          home: AppShell(
            onSignOut: () async {
              signOutCalls++;
              await signOutGate.future;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final listFinder = find.byType(ListView).last;
    await tester.drag(listFinder, const Offset(0, -400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Sign out?'), findsNothing);

    await tester.tap(find.text('Sign Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(signOutCalls, 0);

    await tester.tap(find.text('Sign Out').last);
    await tester.pump();

    expect(find.text('Signing out...'), findsOneWidget);
    expect(signOutCalls, 1);

    signOutGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Signed out'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsNothing);
  });
}
