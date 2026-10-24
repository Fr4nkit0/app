import 'package:drift/drift.dart';

/// Key/value store for sync bookkeeping such as the pull cursor.
class SyncStateTable extends Table {
  @override
  String get tableName => 'sync_state';

  late final key = text()();
  late final value = text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
