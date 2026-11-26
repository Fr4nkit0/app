import 'package:drift/drift.dart';
import 'package:app/features/route/data/database/route.table.dart';

/// Containers the office loaded onto the truck of a route, or a correction
/// of a load; identified by its server id. Only downloaded, never written on
/// the device: what is left on the truck is computed from these rows and the
/// route's container movements.
class RouteContainerLoadTable extends Table {
  @override
  String get tableName => 'route_container_loads';

  late final id = integer()(); // Server id
  late final routeId = text().references(
    RouteTable,
    #routeId,
    onDelete: KeyAction.cascade,
  )();
  late final containerType = text()(); // Catalog code (container_types.code)
  late final quantity = integer()();
  late final type = text()(); // 'load' | 'correction'
  late final reason = text().nullable()();
  late final loadedAt = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
