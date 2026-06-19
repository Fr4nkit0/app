import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'package:app/features/customers/data/database/customer.table.dart';

class SaleTable extends Table with Timestamps {
  @override
  String get tableName => 'sales';

  late final saleId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().references(
    CustomerTable,
    #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final totalAmount = real()();
  late final paymentMethod = text()(); // 'cash' | 'transfer' | 'credit'
  late final saleDate = dateTime().withDefault(currentDateAndTime)();
  late final quantity = integer()();
  late final shipping_amount = real()();
  late final visitId = text().nullable()();
  late final cashAmount = real().nullable()();
  late final transferAmount = real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {saleId};
}
