import 'package:drift/drift.dart';
import 'package:app/features/core/services/database_mixins.dart';

class CustomerAddressTable extends Table with Timestamps {
  @override
  String get tableName => 'customer_addresses';

  late final addressId = text().clientDefault(() => uuid.v4())();
  late final street = text().nullable()();
  late final apartment = text().nullable()();
  late final floor = text().nullable()();
  late final visualReference = text().nullable()();
  late final isPrimary = boolean().withDefault(const Constant(false))();
  late final customerId = text().clientDefault(() => uuid.v4())();

  @override
  Set<Column<Object>> get primaryKey => {addressId};
}
