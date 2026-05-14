import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';

class CustomerTable extends Table with Timestamps {
  @override
  String get tableName => 'customers';

  late final customerId = text().clientDefault(() => uuid.v4())();
  late final name = text()();
  late final phone = text().nullable().unique()();

  @override
  Set<Column<Object>> get primaryKey => {customerId};
}
