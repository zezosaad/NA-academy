import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/features/notifications/data/notifications_repository.dart';

final loadInboxProvider = StreamProvider.autoDispose<List<dynamic>>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getInboxStream();
});
