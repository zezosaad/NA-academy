import 'package:drift/drift.dart';
import 'package:na_app/core/storage/app_database.dart';

class NotificationsLocalDataSource {
  final AppDatabase _db;

  NotificationsLocalDataSource(this._db);

  Future<void> upsert(NotificationsInboxCompanion entry) async {
    await _db.into(_db.notificationsInbox).insertOnConflictUpdate(entry);
  }

  Future<void> markRead(String id) async {
    final query = _db.update(_db.notificationsInbox)
      ..where((t) => t.id.equals(id));
    await query.write(const NotificationsInboxCompanion(
      readAt: Value(1),
    ));
  }

  Future<void> markAllRead() async {
    final query = _db.update(_db.notificationsInbox)
      ..where((t) => t.readAt.isNull());
    await query.write(const NotificationsInboxCompanion(
      readAt: Value(1),
    ));
  }

  Stream<List<NotificationsInboxData>> getInboxStream() {
    return (_db.select(_db.notificationsInbox)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<int> getUnreadCountStream() {
    final countExpr = _db.notificationsInbox.id.count();
    final query = _db.selectOnly(_db.notificationsInbox)
      ..addColumns([countExpr])
      ..where(_db.notificationsInbox.readAt.isNull());
    return query.map((row) => row.read(countExpr)!).watchSingle();
  }

  Future<NotificationsInboxData?> getById(String id) async {
    return (_db.select(_db.notificationsInbox)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
