import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/storage/app_database.dart';
import 'package:na_app/features/notifications/data/notifications_repository.dart';

final inboxStreamProvider =
    StreamProvider.autoDispose<List<NotificationsInboxData>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getInboxStream();
});

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getUnreadCountStream();
});

final inboxControllerProvider = Provider<InboxController>((ref) {
  return InboxController(ref);
});

class InboxController {
  final Ref _ref;

  InboxController(this._ref);

  Future<void> markRead(String id) async {
    final repo = _ref.read(notificationsRepositoryProvider);
    await repo.markRead(id);
  }

  Future<void> markAllRead() async {
    final repo = _ref.read(notificationsRepositoryProvider);
    await repo.markAllRead();
  }

  Future<void> refresh() async {
    final repo = _ref.read(notificationsRepositoryProvider);
    await repo.refreshFromServer();
  }
}
