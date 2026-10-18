import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification reconciliation
  NotificationService.instance.reconcileUpcomingAlarms();

  runApp(const PersonalLifeOSApp());
}
