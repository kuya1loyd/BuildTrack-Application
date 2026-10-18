import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:provider/provider.dart';

import 'screens/app_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/more_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/materials_screen.dart';
import 'state/app_state.dart';

const phoneSize = Size(390, 844);

@Preview(name: 'Landing', group: 'Screens', size: phoneSize)
Widget landingPreview() => LandingScreen(onGetStarted: () {}, onSignIn: () {});

@Preview(name: 'Sign In', group: 'Screens', size: phoneSize)
Widget signInPreview() => SignInScreen(
  onBack: () {},
  onSignUp: () {},
  onForgot: () {},
  onSignIn: ({required email, required password}) async {},
);

@Preview(name: 'Sign Up', group: 'Screens', size: phoneSize)
Widget signUpPreview() => SignUpScreen(
  onBack: () {},
  onSignIn: () {},
  onSignUp:
      ({
        required name,
        required email,
        required password,
        String? company,
        String? phone,
      }) async {},
);

@Preview(name: 'Dashboard (empty account)', group: 'Screens', size: phoneSize)
Widget homePreview() => _withState(const AppShell(onSignOut: noopFuture));

@Preview(name: 'Projects', group: 'Screens', size: phoneSize)
Widget projectsPreview() => _withState(const ProjectsScreen());

@Preview(name: 'Tasks', group: 'Screens', size: phoneSize)
Widget tasksPreview() => _withState(const TasksScreen());

@Preview(name: 'Materials', group: 'Screens', size: phoneSize)
Widget materialsPreview() => _withState(const MaterialsScreen());

@Preview(name: 'More', group: 'Screens', size: phoneSize)
Widget morePreview() =>
    _withState(MoreScreen(onSignOut: noopFuture, onOpenTab: (_) {}));

Future<void> noopFuture() async {}

Widget _withState(Widget screen) {
  return ChangeNotifierProvider.value(
    value: AppState(),
    child: MaterialApp(debugShowCheckedModeBanner: false, home: screen),
  );
}
