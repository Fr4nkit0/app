import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'route.stop.table.dart';
import 'package:app/features/customers/data/database/customer.table.dart';
import 'package:app/features/customers/data/database/customer.address.table.dart';

class RouteVisitTable extends Table with Timestamps {
  @override
  String get tableName => 'visits';

  late final visitId = text().clientDefault(() => uuid.v4())();
  late final routeStopId = text().references(
    RouteStopTable, #routeStopId,
    onDelete: KeyAction.cascade,
  )();
  late final customerId = text().references(
    CustomerTable, #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final visitType = text()(); // matches VisitType enum
  late final outcome = text().withDefault(const Constant('successful'))();
  late final arrived_at = dateTime()();
  late final observations = text().nullable()();
  late final created_at = text().nullable()();
  late final modified_at = text().nullable()();
  late final amountCollected = real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {visitId};
}
