import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'route.table.dart';
import 'package:app/features/customers/data/database/customer.table.dart';
import 'package:app/features/customers/data/database/customer.address.table.dart';

class RouteStopTable extends Table with Timestamps {
  @override
  String get tableName => 'route_stops';

  late final routeStopId = text().clientDefault(() => uuid.v4())();
  late final routeId = text().references(
    RouteTable,
    #routeId,
    onDelete: KeyAction.cascade,
  )();
  late final customerId = text().references(
    CustomerTable,
    #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final customerAddressId = text().nullable().references(
    CustomerAddressTable,
    #addressId,
    onDelete: KeyAction.setNull,
  )();
  late final sequence = integer()();
  late final status = text().withDefault(const Constant('pending'))();
  late final scheduledAt = dateTime()();
  late final visitedAt = dateTime().nullable()();
  late final notes = text().nullable()();
  late final scheduledTime = text().nullable()(); // 'HH:MM:SS'
  late final rescheduledFromStopId = text().nullable()();

  /// Set by the server when the stop carries a visit the admin scheduled.
  late final isRequested = boolean().withDefault(const Constant(false))();

  /// The admin's note for a requested visit.
  late final note = text().nullable()();
  late final scheduledVisitId = integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {routeStopId};
}
