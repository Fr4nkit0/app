import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'package:app/features/customers/data/database/customer.table.dart';
import 'package:app/features/visits/data/database/visit.table.dart';
import 'package:app/features/route/data/repositories/database/route.table.dart';
import 'package:app/features/products/data/database/product.table.dart';

class ContainerMovementTable extends Table with Timestamps {
  @override
  String get tableName => 'container_movements';

  late final containerMovementId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().references(
    CustomerTable, #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final containerType = text()(); // 'BIDON_20L' | 'SIFON_2L'
  late final deliveredQuantity = integer()();
  late final returnedQuantity = integer()();
  late final visitId = text().nullable().references(
    VisitTable, #visitId,
    onDelete: KeyAction.setNull,
  )();
  late final routeId = text().nullable().references(
    RouteTable, #routeId,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column<Object>> get primaryKey => {containerMovementId};
}

class CustomerContainerBalanceTable extends Table with Timestamps {
  @override
  String get tableName => 'customer_container_balances';

  late final customerId = text().references(
    CustomerTable, #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final containerType = text()(); // 'BIDON_20L' | 'SIFON_2L'
  late final quantity = integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {customerId, containerType};
}

class RouteInventoryLoadTable extends Table with Timestamps {
  @override
  String get tableName => 'route_inventory_loads';

  late final routeInventoryLoadId = text().clientDefault(() => uuid.v4())();
  late final routeId = text().references(
    RouteTable, #routeId,
    onDelete: KeyAction.restrict,
  )();
  late final productId = text().references(
    ProductTable, #productId,
    onDelete: KeyAction.restrict,
  )();
  late final quantity = integer()();
  late final loadedAt = dateTime().withDefault(currentDateAndTime)();
  late final createdBy = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {routeInventoryLoadId};
}
