import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'build_track_app.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..boot(),
      child: const BuildTrackApp(),
    ),
  );
}
