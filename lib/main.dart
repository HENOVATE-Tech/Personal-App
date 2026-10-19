import 'package:flutter/material.dart';
import 'app.dart';
import 'core/database/local_database.dart';
import 'core/services/api_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize permanent local storage (never lost across browser refreshes or device reboots)
  await LocalDatabase.instance.initStorage();

  // 2. Initialize notification reconciliation
  NotificationService.instance.reconcileUpcomingAlarms();

  // 3. Detect active backend and run live two-way sync with Supabase PostgreSQL
  ApiService.instance.detectBestBaseUrl().then((_) {
    ApiService.instance.syncAll(LocalDatabase.instance);
  }).catchError((_) {});

  runApp(const PersonalLifeOSApp());
}

