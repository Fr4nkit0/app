import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'package:app/lib/features/sales/data/database/product.table.dart';

class RouteInventoryTable extends Table with Timestamps {
  @override
  String get tableName => 'inventory_movements';

  late final inventoryMovementId = text().clientDefault(() => uuid.v4())();
  late final productId = text().references(
    ProductTable, #productId,
    onDelete: KeyAction.restrict,
  )();
  late final movementType = text()(); // 'in' | 'out' | 'adjustment'
  late final quantity = integer()(); // signed: +in, -out
  late final reason = text()(); // 'sale' | 'restock' | 'return' | 'damage' | 'manual_adjustment'
  late final movementDate = dateTime().withDefault(currentDateAndTime)();
  late final notes = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {inventoryMovementId};
}