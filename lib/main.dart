import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/family_provider.dart';
import 'providers/evidence_provider.dart';
import 'providers/task_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/achievement_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://nlxuedndnvybiqimejdm.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5seHVlZG5kbnZ5YmlxaW1lamRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NTMzOTgsImV4cCI6MjA5NDUyOTM5OH0.lyU-j5mPmCNIVDGjBfKXj6KrluD8FQGaluGtkItNxDE',
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => EvidenceProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: const HabitikApp(),
    ),
  );
}
