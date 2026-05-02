import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:na_app/firebase_options.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

@pragma('vm:entry-point')
Future<void> initializeNotifications() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  _log.i('FCM permission status: ${settings.authorizationStatus}');

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    _log.i('FCM token refreshed');
  });
}
