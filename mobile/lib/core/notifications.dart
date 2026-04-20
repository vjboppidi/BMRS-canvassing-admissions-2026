import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps `flutter_local_notifications`. Push (FCM/SNS) is intentionally stubbed —
/// the app fires local notifications for reminders that work offline; when
/// connectivity is available the reminder log is also synced to the backend so
/// a later server-side push pipeline can take over.
class AppNotifications {
  AppNotifications() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'bmrs_reminders';
  static const _channelName = 'Follow-up reminders';
  static const _channelDescription = 'Notifications for canvassing follow-ups';

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Schedule a local notification for [when] with a stable [id] (hash of the
  /// reminder UUID). If [when] is in the past, fire immediately.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();

    final whenLocal = tz.TZDateTime.from(when, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      if (whenLocal.isBefore(tz.TZDateTime.now(tz.local))) {
        await _plugin.show(id, title, body, details);
      } else {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          whenLocal,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e, st) {
      // Notifications are best-effort — don't crash the app if the platform
      // refuses (e.g. permissions denied).
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to schedule notification: $e\n$st');
      }
    }
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }
}
