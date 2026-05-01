import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

class LocalNotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    const androidChannel = AndroidNotificationChannel(
      'na_academy_default',
      'NA Academy Notifications',
      description: 'Default notification channel for NA Academy',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    _log.i('Local notifications initialized');
  }

  static Future<void> showForegroundBanner({
    required String title,
    required String body,
    String? notificationId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'na_academy_default',
      'NA Academy Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      notificationId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
    );
  }
}
