import 'dart:io';
import 'package:flutter/foundation.dart';

/// Runtime configuration for the mobile app.
///
/// The default [apiBaseUrl] tries to do the right thing for each platform:
/// - Android emulator: `http://10.0.2.2:4000` (host machine loopback).
/// - iOS simulator / desktop / web: `http://localhost:4000`.
///
/// In a release build you should point this at your real backend, e.g. via
/// `--dart-define=API_BASE_URL=https://api.example.com`.
class AppConfig {
  const AppConfig._();

  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kIsWeb) return 'http://localhost:4000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } on UnsupportedError {
      // Platform.isAndroid isn't available on web; already handled by kIsWeb.
    }
    return 'http://localhost:4000';
  }

  static const Duration syncInterval = Duration(minutes: 2);
  static const Duration connectivityRetry = Duration(seconds: 30);
}
