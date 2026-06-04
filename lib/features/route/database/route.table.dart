import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';

class RouteTable extends Table with Timestamps {
  @override
  String get tableName => 'routes';

  late final routeId = text().clientDefault(() => uuid.v4())();
  late final name = text()();
  late final dayOfWeek = integer().withDefault(const Constant(0))(); // 0-6
  late final driverName = text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {routeId};
}