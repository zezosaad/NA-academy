import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:na_app/core/storage/app_database.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log.i('Background push received: ${message.messageId}');
  await _upsertToInbox(message);
}

Future<void> _upsertToInbox(RemoteMessage message) async {
  try {
    final db = AppDatabase();
    final data = message.data;
    final notifId = extractNotificationId(message) ?? '';
    if (notifId.isEmpty) return;

    await db.into(db.notificationsInbox).insertOnConflictUpdate(
          NotificationsInboxCompanion(
            id: Value(notifId),
            title: Value(message.notification?.title ?? ''),
            body: Value(message.notification?.body ?? ''),
            data: Value(data.isNotEmpty ? jsonEncode(data) : null),
            senderName: Value(data['senderName'] ?? ''),
            createdAt: Value(message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch),
            readAt: const Value.absent(),
            lastSyncedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  } catch (e) {
    _log.e('Failed to upsert notification to inbox: $e');
  }
}

String? extractNotificationId(RemoteMessage message) {
  final data = message.data;

  final explicitId = data['notificationId'];
  if (explicitId != null && explicitId.toString().isNotEmpty) {
    return explicitId.toString();
  }

  // Legacy fallback: use `id` only for generic notifications without deep-link types.
  final legacyId = data['id'];
  final type = data['type'];
  if ((type == null || type.toString().isEmpty) &&
      legacyId != null &&
      legacyId.toString().isNotEmpty) {
    return legacyId.toString();
  }

  final messageId = message.messageId;
  if (messageId != null && messageId.isNotEmpty) {
    return messageId;
  }

  return null;
}

Future<void> handleForegroundMessage(RemoteMessage message) async {
  _log.i('Foreground push received: ${message.messageId}');
  await _upsertToInbox(message);
}

Future<void> handleMessageOpenedApp(RemoteMessage message) async {
  _log.i('Push opened from background: ${message.messageId}');
  try {
    await _upsertToInbox(message);
  } catch (e) {
    _log.e('Failed to persist opened notification: $e');
  }
}

Future<void> handleInitialMessage(RemoteMessage? message) async {
  if (message == null) return;
  _log.i('Cold-start push: ${message.messageId}');
  try {
    await _upsertToInbox(message);
  } catch (e) {
    _log.e('Failed to persist initial notification: $e');
  }
}

String? extractDeepLinkTarget(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] as String?;
  if (type == null) return null;

  switch (type) {
    case 'exam':
      final id = data['id'];
      return id != null ? '/exams/$id' : null;
    case 'subject':
      final id = data['id'];
      return id != null ? '/subjects/$id' : null;
    case 'lesson':
      final subjectId = data['subjectId'];
      final lessonId = data['id'];
      if (subjectId != null && lessonId != null) {
        return '/subjects/$subjectId/lessons/$lessonId';
      }
      return null;
    case 'url':
      return data['url'];
    default:
      return null;
  }
}
