import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';

class RouteTable extends Table with Timestamps {
  @override
  String get tableName => 'routes';

  late final routeId = text().clientDefault(() => uuid.v4())();
  late final driverName = text().nullable()();
  late final route_date = text()();
  late final started_at = integer().withDefault(const Constant(0))(); // 0-6
  late final completed_at = text().nullable()();
  // late final created_at = text().nullable()();
  late final last_modified = text().nullable()();
  late final available = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {routeId};
}
