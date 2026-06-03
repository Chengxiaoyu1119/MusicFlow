import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/desktop/services/window_manager_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop window manager (only on desktop platforms)
  if (WindowManagerService.isSupported) {
    await WindowManagerService().init();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: MusicPlayerApp()));
}
