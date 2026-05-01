import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class NotificationsInbox extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get data => text().nullable()();
  TextColumn get senderName => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get readAt => integer().nullable()();
  IntColumn get lastSyncedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class NotificationsUnreadIndex extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get count => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [NotificationsInbox, NotificationsUnreadIndex])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}na_app.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
