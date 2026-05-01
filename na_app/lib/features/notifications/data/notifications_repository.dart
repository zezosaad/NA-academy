import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/storage/app_database.dart';
import 'package:na_app/features/notifications/data/notifications_local_data_source.dart';
import 'package:na_app/features/notifications/data/notifications_remote_data_source.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(
    local: NotificationsLocalDataSource(ref.watch(appDatabaseProvider)),
    remote: ref.watch(notificationsRemoteDataSourceProvider),
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

class NotificationsRepository {
  final NotificationsLocalDataSource _local;
  final NotificationsRemoteDataSource _remote;

  NotificationsRepository({
    required NotificationsLocalDataSource local,
    required NotificationsRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  Stream<List<NotificationsInboxData>> getInboxStream() {
    return _local.getInboxStream();
  }

  Stream<int> getUnreadCountStream() {
    return _local.getUnreadCountStream();
  }

  Future<void> refreshFromServer({int limit = 50}) async {
    try {
      final response = await _remote.getInbox(limit: limit);
      final items = response['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        await _local.upsert(NotificationsInboxCompanion(
          id: Value(map['id'] as String),
          title: Value(map['title'] as String),
          body: Value(map['body'] as String),
          data: Value(map['data'] != null ? jsonEncode(map['data']) : null),
          senderName: Value(map['senderName'] as String?),
          createdAt: Value(DateTime.parse(map['createdAt'] as String).millisecondsSinceEpoch),
          readAt: Value(map['readAt'] != null
              ? DateTime.parse(map['readAt'] as String).millisecondsSinceEpoch
              : null),
          lastSyncedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
      }
    } catch (_) {}
  }

  Future<void> markRead(String notificationId) async {
    await _local.markRead(notificationId);
    try {
      await _remote.markRead(notificationId);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    await _local.markAllRead();
    try {
      await _remote.markAllRead();
    } catch (_) {}
  }
}
