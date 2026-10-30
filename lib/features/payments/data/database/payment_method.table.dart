import 'package:drift/drift.dart';

/// Catalog row identified by its server id.
class PaymentMethodTable extends Table {
  @override
  String get tableName => 'payment_methods';

  late final id = integer()();
  late final code = text()();
  late final name = text()();
  late final enabled = boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
