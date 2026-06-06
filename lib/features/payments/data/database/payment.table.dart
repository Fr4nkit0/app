import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'package:app/features/customers/data/database/customer.table.dart';
import 'package:app/features/visits/data/database/visit.table.dart';
import 'package:app/features/sales/data/database/sales.table.dart';

class PaymentTable extends Table with Timestamps {
  @override
  String get tableName => 'payments';

  late final paymentId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().references(
    CustomerTable, #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final amount = real()();
  late final paymentMethod = text()(); // 'EFECTIVO' | 'TRANSFERENCIA' | 'TARJETA' | 'CREDIT'
  late final visitId = text().nullable().references(
    VisitTable, #visitId,
    onDelete: KeyAction.setNull,
  )();
  late final saleId = text().nullable().references(
    SaleTable, #saleId,
    onDelete: KeyAction.setNull,
  )();
  late final notes = text().nullable()();
  late final status = text().withDefault(const Constant('CONFIRMED'))(); // 'CONFIRMED' | 'CANCELLED' | 'ANNULLED'

  @override
  Set<Column<Object>> get primaryKey => {paymentId};
}

class CustomerAccountEntryTable extends Table with Timestamps {
  @override
  String get tableName => 'customer_account_entries';

  late final customerAccountEntryId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().references(
    CustomerTable, #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final saleId = text().nullable().references(
    SaleTable, #saleId,
    onDelete: KeyAction.setNull,
  )();
  late final paymentId = text().nullable().references(
    PaymentTable, #paymentId,
    onDelete: KeyAction.setNull,
  )();
  late final createdBy = text().nullable()();
  late final entryType = text()(); // 'SALE' | 'PAYMENT' | 'ADJUSTMENT' | 'CREDIT_NOTE'
  late final amount = real()();
  late final direction = integer()(); // -1 for credit/payment, +1 for debit/sale
  late final description = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {customerAccountEntryId};
}

class CustomerBalanceTable extends Table with Timestamps {
  @override
  String get tableName => 'customer_balances';

  late final customerId = text().references(
    CustomerTable, #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final currentBalance = real().withDefault(const Constant(0.0))();
  late final lastEntryId = text().nullable().references(
    CustomerAccountEntryTable, #customerAccountEntryId,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column<Object>> get primaryKey => {customerId};
}
