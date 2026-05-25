import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 1. Firebase must init first (reads google-services.json)
  await Firebase.initializeApp();

  // 2. Local storage for tasks / habits / focus / settings
  await HiveService().init();

  // 3. Auth metadata box (pending email, resend timestamps)
  await AuthService().init();

  // 4. Firestore offline persistence
  await FirestoreService().init();

  // 5. Notifications (heads-up channel + permission request)
  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: TrackerApp(),
    ),
  );
}
