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

  /// Money columns hold whole pesos.
  late final totalAmount = integer()();
  late final paymentMethod = text()(); // 'cash' | 'transfer' | 'credit'
  late final saleDate = dateTime().withDefault(currentDateAndTime)();
  late final quantity = integer()();
  late final shipping_amount = integer()();
  late final visitId = text().nullable()();
  late final cashAmount = integer().nullable()();
  late final transferAmount = integer().nullable()();
  late final status = text().withDefault(
    const Constant('CONFIRMED'),
  )(); // RecordStatus.confirmed, as a literal the generated code can copy
  late final cancelledAt = dateTime().nullable()();
  late final cancellationReason = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {saleId};
}
