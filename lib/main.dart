import 'package:flutter/material.dart';
import 'app.dart';
import 'core/database/local_database.dart';
import 'core/services/api_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification reconciliation
  NotificationService.instance.reconcileUpcomingAlarms();

  // Asynchronously detect active backend and run sync in background
  ApiService.instance.detectBestBaseUrl().then((_) {
    ApiService.instance.syncAll(LocalDatabase.instance);
  }).catchError((_) {});

  runApp(const PersonalLifeOSApp());
}

