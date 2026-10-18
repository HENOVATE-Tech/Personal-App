import 'package:flutter/material.dart';
import 'core/config/app_constants.dart';
import 'core/config/theme.dart';
import 'core/widgets/app_shell.dart';

class PersonalLifeOSApp extends StatelessWidget {
  const PersonalLifeOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
