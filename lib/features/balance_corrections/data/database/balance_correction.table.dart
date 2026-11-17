import 'package:drift/drift.dart';

import 'package:app/core/services/database_mixins.dart';
import 'package:app/features/customers/data/database/customer.table.dart';

/// A balance the driver counted and corrected: the money debt of a
/// customer, or their custody of one container type. The local balance
/// moves by `counted - seen_balance`, the same difference the server adds.
class BalanceCorrectionTable extends Table with Timestamps {
  @override
  String get tableName => 'balance_corrections';

  late final correctionId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().references(
    CustomerTable,
    #customerId,
    onDelete: KeyAction.restrict,
  )();
  late final visitId = text().nullable()();

  /// `debt` or `containers` (BalanceTarget wire name).
  late final target = text()();

  /// Catalog code (container_types.code); only for `containers`.
  late final containerType = text().nullable()();

  /// The real balance the driver counted (debt: positive means owed).
  late final counted = real()();

  /// The local balance shown when the driver corrected it.
  late final seenBalance = real()();
  late final reason = text()();
  late final correctedAt = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {correctionId};
}
