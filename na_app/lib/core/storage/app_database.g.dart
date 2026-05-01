// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotificationsInboxTable extends NotificationsInbox
    with TableInfo<$NotificationsInboxTable, NotificationsInboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsInboxTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> readAt = GeneratedColumn<int>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    data,
    senderName,
    createdAt,
    readAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications_inbox';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationsInboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationsInboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $NotificationsInboxTable createAlias(String alias) {
    return $NotificationsInboxTable(attachedDatabase, alias);
  }
}

class NotificationsInboxData extends DataClass
    implements Insertable<NotificationsInboxData> {
  final String id;
  final String title;
  final String body;
  final String? data;
  final String? senderName;
  final int createdAt;
  final int? readAt;
  final int lastSyncedAt;
  const NotificationsInboxData({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    this.senderName,
    required this.createdAt,
    this.readAt,
    required this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<int>(readAt);
    }
    map['last_synced_at'] = Variable<int>(lastSyncedAt);
    return map;
  }

  NotificationsInboxCompanion toCompanion(bool nullToAbsent) {
    return NotificationsInboxCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      createdAt: Value(createdAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory NotificationsInboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationsInboxData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      data: serializer.fromJson<String?>(json['data']),
      senderName: serializer.fromJson<String?>(json['senderName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      readAt: serializer.fromJson<int?>(json['readAt']),
      lastSyncedAt: serializer.fromJson<int>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'data': serializer.toJson<String?>(data),
      'senderName': serializer.toJson<String?>(senderName),
      'createdAt': serializer.toJson<int>(createdAt),
      'readAt': serializer.toJson<int?>(readAt),
      'lastSyncedAt': serializer.toJson<int>(lastSyncedAt),
    };
  }

  NotificationsInboxData copyWith({
    String? id,
    String? title,
    String? body,
    Value<String?> data = const Value.absent(),
    Value<String?> senderName = const Value.absent(),
    int? createdAt,
    Value<int?> readAt = const Value.absent(),
    int? lastSyncedAt,
  }) => NotificationsInboxData(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    data: data.present ? data.value : this.data,
    senderName: senderName.present ? senderName.value : this.senderName,
    createdAt: createdAt ?? this.createdAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
  NotificationsInboxData copyWithCompanion(NotificationsInboxCompanion data) {
    return NotificationsInboxData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      data: data.data.present ? data.data.value : this.data,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsInboxData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('data: $data, ')
          ..write('senderName: $senderName, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    data,
    senderName,
    createdAt,
    readAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationsInboxData &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.data == this.data &&
          other.senderName == this.senderName &&
          other.createdAt == this.createdAt &&
          other.readAt == this.readAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class NotificationsInboxCompanion
    extends UpdateCompanion<NotificationsInboxData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> data;
  final Value<String?> senderName;
  final Value<int> createdAt;
  final Value<int?> readAt;
  final Value<int> lastSyncedAt;
  final Value<int> rowid;
  const NotificationsInboxCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.data = const Value.absent(),
    this.senderName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsInboxCompanion.insert({
    required String id,
    required String title,
    required String body,
    this.data = const Value.absent(),
    this.senderName = const Value.absent(),
    required int createdAt,
    this.readAt = const Value.absent(),
    required int lastSyncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<NotificationsInboxData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? data,
    Expression<String>? senderName,
    Expression<int>? createdAt,
    Expression<int>? readAt,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (data != null) 'data': data,
      if (senderName != null) 'sender_name': senderName,
      if (createdAt != null) 'created_at': createdAt,
      if (readAt != null) 'read_at': readAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsInboxCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? data,
    Value<String?>? senderName,
    Value<int>? createdAt,
    Value<int?>? readAt,
    Value<int>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return NotificationsInboxCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<int>(readAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsInboxCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('data: $data, ')
          ..write('senderName: $senderName, ')
          ..write('createdAt: $createdAt, ')
          ..write('readAt: $readAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsUnreadIndexTable extends NotificationsUnreadIndex
    with
        TableInfo<
          $NotificationsUnreadIndexTable,
          NotificationsUnreadIndexData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsUnreadIndexTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications_unread_index';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationsUnreadIndexData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationsUnreadIndexData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $NotificationsUnreadIndexTable createAlias(String alias) {
    return $NotificationsUnreadIndexTable(attachedDatabase, alias);
  }
}

class NotificationsUnreadIndexData extends DataClass
    implements Insertable<NotificationsUnreadIndexData> {
  final int id;
  final int count;
  const NotificationsUnreadIndexData({required this.id, required this.count});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['count'] = Variable<int>(count);
    return map;
  }

  NotificationsUnreadIndexCompanion toCompanion(bool nullToAbsent) {
    return NotificationsUnreadIndexCompanion(
      id: Value(id),
      count: Value(count),
    );
  }

  factory NotificationsUnreadIndexData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationsUnreadIndexData(
      id: serializer.fromJson<int>(json['id']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'count': serializer.toJson<int>(count),
    };
  }

  NotificationsUnreadIndexData copyWith({int? id, int? count}) =>
      NotificationsUnreadIndexData(
        id: id ?? this.id,
        count: count ?? this.count,
      );
  NotificationsUnreadIndexData copyWithCompanion(
    NotificationsUnreadIndexCompanion data,
  ) {
    return NotificationsUnreadIndexData(
      id: data.id.present ? data.id.value : this.id,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsUnreadIndexData(')
          ..write('id: $id, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationsUnreadIndexData &&
          other.id == this.id &&
          other.count == this.count);
}

class NotificationsUnreadIndexCompanion
    extends UpdateCompanion<NotificationsUnreadIndexData> {
  final Value<int> id;
  final Value<int> count;
  const NotificationsUnreadIndexCompanion({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
  });
  NotificationsUnreadIndexCompanion.insert({
    this.id = const Value.absent(),
    this.count = const Value.absent(),
  });
  static Insertable<NotificationsUnreadIndexData> custom({
    Expression<int>? id,
    Expression<int>? count,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (count != null) 'count': count,
    });
  }

  NotificationsUnreadIndexCompanion copyWith({
    Value<int>? id,
    Value<int>? count,
  }) {
    return NotificationsUnreadIndexCompanion(
      id: id ?? this.id,
      count: count ?? this.count,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsUnreadIndexCompanion(')
          ..write('id: $id, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotificationsInboxTable notificationsInbox =
      $NotificationsInboxTable(this);
  late final $NotificationsUnreadIndexTable notificationsUnreadIndex =
      $NotificationsUnreadIndexTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notificationsInbox,
    notificationsUnreadIndex,
  ];
}

typedef $$NotificationsInboxTableCreateCompanionBuilder =
    NotificationsInboxCompanion Function({
      required String id,
      required String title,
      required String body,
      Value<String?> data,
      Value<String?> senderName,
      required int createdAt,
      Value<int?> readAt,
      required int lastSyncedAt,
      Value<int> rowid,
    });
typedef $$NotificationsInboxTableUpdateCompanionBuilder =
    NotificationsInboxCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> body,
      Value<String?> data,
      Value<String?> senderName,
      Value<int> createdAt,
      Value<int?> readAt,
      Value<int> lastSyncedAt,
      Value<int> rowid,
    });

class $$NotificationsInboxTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsInboxTable> {
  $$NotificationsInboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsInboxTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsInboxTable> {
  $$NotificationsInboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsInboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsInboxTable> {
  $$NotificationsInboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$NotificationsInboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsInboxTable,
          NotificationsInboxData,
          $$NotificationsInboxTableFilterComposer,
          $$NotificationsInboxTableOrderingComposer,
          $$NotificationsInboxTableAnnotationComposer,
          $$NotificationsInboxTableCreateCompanionBuilder,
          $$NotificationsInboxTableUpdateCompanionBuilder,
          (
            NotificationsInboxData,
            BaseReferences<
              _$AppDatabase,
              $NotificationsInboxTable,
              NotificationsInboxData
            >,
          ),
          NotificationsInboxData,
          PrefetchHooks Function()
        > {
  $$NotificationsInboxTableTableManager(
    _$AppDatabase db,
    $NotificationsInboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsInboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsInboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsInboxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> readAt = const Value.absent(),
                Value<int> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsInboxCompanion(
                id: id,
                title: title,
                body: body,
                data: data,
                senderName: senderName,
                createdAt: createdAt,
                readAt: readAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String body,
                Value<String?> data = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                required int createdAt,
                Value<int?> readAt = const Value.absent(),
                required int lastSyncedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationsInboxCompanion.insert(
                id: id,
                title: title,
                body: body,
                data: data,
                senderName: senderName,
                createdAt: createdAt,
                readAt: readAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsInboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsInboxTable,
      NotificationsInboxData,
      $$NotificationsInboxTableFilterComposer,
      $$NotificationsInboxTableOrderingComposer,
      $$NotificationsInboxTableAnnotationComposer,
      $$NotificationsInboxTableCreateCompanionBuilder,
      $$NotificationsInboxTableUpdateCompanionBuilder,
      (
        NotificationsInboxData,
        BaseReferences<
          _$AppDatabase,
          $NotificationsInboxTable,
          NotificationsInboxData
        >,
      ),
      NotificationsInboxData,
      PrefetchHooks Function()
    >;
typedef $$NotificationsUnreadIndexTableCreateCompanionBuilder =
    NotificationsUnreadIndexCompanion Function({
      Value<int> id,
      Value<int> count,
    });
typedef $$NotificationsUnreadIndexTableUpdateCompanionBuilder =
    NotificationsUnreadIndexCompanion Function({
      Value<int> id,
      Value<int> count,
    });

class $$NotificationsUnreadIndexTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsUnreadIndexTable> {
  $$NotificationsUnreadIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsUnreadIndexTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsUnreadIndexTable> {
  $$NotificationsUnreadIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsUnreadIndexTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsUnreadIndexTable> {
  $$NotificationsUnreadIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$NotificationsUnreadIndexTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsUnreadIndexTable,
          NotificationsUnreadIndexData,
          $$NotificationsUnreadIndexTableFilterComposer,
          $$NotificationsUnreadIndexTableOrderingComposer,
          $$NotificationsUnreadIndexTableAnnotationComposer,
          $$NotificationsUnreadIndexTableCreateCompanionBuilder,
          $$NotificationsUnreadIndexTableUpdateCompanionBuilder,
          (
            NotificationsUnreadIndexData,
            BaseReferences<
              _$AppDatabase,
              $NotificationsUnreadIndexTable,
              NotificationsUnreadIndexData
            >,
          ),
          NotificationsUnreadIndexData,
          PrefetchHooks Function()
        > {
  $$NotificationsUnreadIndexTableTableManager(
    _$AppDatabase db,
    $NotificationsUnreadIndexTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsUnreadIndexTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NotificationsUnreadIndexTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationsUnreadIndexTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => NotificationsUnreadIndexCompanion(id: id, count: count),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => NotificationsUnreadIndexCompanion.insert(
                id: id,
                count: count,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsUnreadIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsUnreadIndexTable,
      NotificationsUnreadIndexData,
      $$NotificationsUnreadIndexTableFilterComposer,
      $$NotificationsUnreadIndexTableOrderingComposer,
      $$NotificationsUnreadIndexTableAnnotationComposer,
      $$NotificationsUnreadIndexTableCreateCompanionBuilder,
      $$NotificationsUnreadIndexTableUpdateCompanionBuilder,
      (
        NotificationsUnreadIndexData,
        BaseReferences<
          _$AppDatabase,
          $NotificationsUnreadIndexTable,
          NotificationsUnreadIndexData
        >,
      ),
      NotificationsUnreadIndexData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotificationsInboxTableTableManager get notificationsInbox =>
      $$NotificationsInboxTableTableManager(_db, _db.notificationsInbox);
  $$NotificationsUnreadIndexTableTableManager get notificationsUnreadIndex =>
      $$NotificationsUnreadIndexTableTableManager(
        _db,
        _db.notificationsUnreadIndex,
      );
}
