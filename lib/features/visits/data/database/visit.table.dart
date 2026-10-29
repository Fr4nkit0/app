import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'package:app/features/route/data/database/route.stop.table.dart';
import 'package:app/features/customers/data/database/customer.table.dart';
import 'visit_outcome.table.dart';

class VisitTable extends Table with Timestamps {
  @override
  String get tableName => 'visits';

  late final visitId = text().clientDefault(() => uuid.v4())();
  late final routeStopId = text().references(
    RouteStopTable,
    #routeStopId,
    onDelete: KeyAction.cascade,
  )();
  late final customerId = text().references(
    CustomerTable,
    #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final visitType = text()();
  late final outcomeId = integer().nullable().references(
    VisitOutcomeTable,
    #id,
    onDelete: KeyAction.setNull,
  )();
  late final arrived_at = dateTime()();
  late final observations = text().nullable()();
  late final amountCollected = real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {visitId};
}
