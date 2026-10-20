import 'package:drift/drift.dart';

/// Catalog row identified by its server id.
class ContainerTypeTable extends Table {
  @override
  String get tableName => 'container_types';

  late final id = integer()();
  late final code = text()();
  late final description = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
