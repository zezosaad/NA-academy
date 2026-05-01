import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/features/notifications/data/notifications_repository.dart';

final markAsReadProvider = Provider<Future<void> Function(String)>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return (notificationId) => repo.markRead(notificationId);
});
