import 'package:drift/drift.dart';

/// Catalog row identified by its server id.
class VisitOutcomeTable extends Table {
  @override
  String get tableName => 'visit_outcomes';

  late final id = integer()();
  /// Stable server code (absent, refused, reschedule) that picks how it is shown.
  late final code = text().nullable()();
  late final name = text()();
  late final triggersReschedule =
      boolean().withDefault(const Constant(false))();
  late final enabled = boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
