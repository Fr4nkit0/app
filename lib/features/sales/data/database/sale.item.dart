import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'sales.table.dart';
import 'sales.product.table.dart';

class SaleItemTable extends Table with Timestamps {
  @override
  String get tableName => 'sale_items';

  late final saleItemId = text().clientDefault(() => uuid.v4())();
  late final saleId = text().references(
    SaleTable, #saleId,
    onDelete: KeyAction.cascade,
  )();
  late final productId = text().references(
    ProductTable, #productId,
    onDelete: KeyAction.restrict,
  )();
  late final quantity = integer()();
  late final unitPrice = real()();
  late final subtotal = real()();

  @override
  Set<Column<Object>> get primaryKey => {saleItemId};
}