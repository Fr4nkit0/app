import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';

class ProductTable extends Table with Timestamps {
  @override
  String get tableName => 'products';

  late final productId = text().clientDefault(() => uuid.v4())();
  late final name = text()();
  late final description = text().nullable()();
  late final price = real()();
  late final stock = integer().withDefault(const Constant(0))();
  late final created_at = dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}