import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';
import 'package:app/features/products/data/database/product.table.dart';
import 'customer.table.dart';

class CustomerAgreementTable extends Table with Timestamps {
  @override
  String get tableName => 'customer_agreements';

  late final agreementId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().references(
    CustomerTable,
    #customerId,
    onDelete: KeyAction.cascade,
  )();
  late final productId = text().references(
    ProductTable,
    #productId,
    onDelete: KeyAction.cascade,
  )();
  late final unitPrice = real()();
  late final validFrom = text()();
  late final validTo = text().nullable()();
  late final reason = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {agreementId};
}
