import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log.i('Background push received: ${message.messageId}');
}
