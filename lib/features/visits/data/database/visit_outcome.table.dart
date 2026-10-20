import 'package:drift/drift.dart';

/// Catalog row identified by its server id.
class VisitOutcomeTable extends Table {
  @override
  String get tableName => 'visit_outcomes';

  late final id = integer()();
  late final name = text()();
  late final triggersReschedule =
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
