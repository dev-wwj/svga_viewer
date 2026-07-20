import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'generated/app_localizations.dart';
import 'preview/workspace_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isMacOS) {
    const config = MacosWindowUtilsConfig();
    await config.apply();
  }
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1120, 720),
    minimumSize: Size(760, 520),
    maximumSize: Size.infinite,
    center: true,
    backgroundColor: MacosColors.transparent,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitle('Motion Preview');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the platform-native macOS neutral surfaces and dynamic label
    // colors so the inspector remains readable in both appearances.
    final lightTheme = MacosThemeData.light();
    final darkTheme = MacosThemeData.dark();
    return MacosApp(
      title: 'Motion Preview',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const WorkspacePage(),
    );
  }
}
