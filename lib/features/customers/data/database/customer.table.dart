import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';

class CustomerTable extends Table with Timestamps {
  @override
  String get tableName => 'customers';

  late final customerId = text().clientDefault(() => uuid.v4())();
  late final name = text()();
  late final phone = text().nullable().unique()();

  /// Set by the server when the driver only gets this customer through
  /// covered stops; false for an own customer.
  late final isCover = boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {customerId};
}
