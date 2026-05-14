import 'package:drift/drift.dart';
import 'package:app/features/core/services/database_mixins.dart';

class CustomerPreferenceTable extends Table with Timestamps {
  @override
  String get tableName => 'customer_preferences';

  late final customerPreferenceId = text().clientDefault(() => uuid.v4())();
  late final customerId = text().clientDefault(() => uuid.v4())();
  late final dayOfWeek = integer().clientDefault(() => 0)();
  late final timeWindowStart = text()();
  late final timeWindowEnd = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {customerPreferenceId};
}
