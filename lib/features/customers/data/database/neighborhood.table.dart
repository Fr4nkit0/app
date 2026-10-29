import 'package:drift/drift.dart';

/// Neighborhood catalog row identified by its server id.
///
/// Addresses keep the neighborhood as its name, never this id.
class NeighborhoodTable extends Table {
  @override
  String get tableName => 'neighborhoods';

  late final id = integer()();
  late final name = text()();
  late final enabled = boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
