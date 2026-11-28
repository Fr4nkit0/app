import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'sales.table.dart';
import 'package:app/features/products/data/database/product.table.dart';

class SaleItemTable extends Table with Timestamps {
  @override
  String get tableName => 'sale_items';

  late final saleItemId = text().clientDefault(() => uuid.v4())();
  late final saleId = text().references(
    SaleTable,
    #saleId,
    onDelete: KeyAction.cascade,
  )();
  late final productId = text().references(
    ProductTable,
    #productId,
    onDelete: KeyAction.restrict,
  )();
  late final quantity = integer()();

  /// Whole pesos.
  late final unitPrice = integer()();
  late final subtotal = integer()();

  /// Server id of the customer agreement that set [unitPrice]; null for
  /// the list price.
  late final agreementServerId = integer().nullable()();

  /// Local uuid of that agreement, for agreements the server did not know
  /// yet when the sale was made.
  late final agreementUuid = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {saleItemId};
}
