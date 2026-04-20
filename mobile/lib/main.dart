import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/notifications.dart';
import 'data/local_db.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final db = await LocalDb.open();
  final notifications = AppNotifications();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        localDbProvider.overrideWithValue(db),
        notificationsProvider.overrideWithValue(notifications),
      ],
      child: const BmrsApp(),
    ),
  );
}
