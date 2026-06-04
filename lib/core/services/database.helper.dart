import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/customers/data/database/customer.table.dart';
import '../../features/customers/data/database/customer.address.table.dart';
import '../../features/customers/data/database/customer.preference.table.dart';
import 'package:app/features/route/database/route.stop.table.dart';
import 'package:app/features/route/database/route.inventory.movement.table.dart';
import 'package:app/features/route/database/route.visits.table.dart';
import 'package:app/features/route/database/route.table.dart';

import 'database_mixins.dart';

part 'database.helper.g.dart';

@DriftDatabase(
  tables: [CustomerTable, 
  CustomerAddressTable, 
  CustomerPreferenceTable,
  RouteTable,
  RouteStopTable,
  RouteVisitTable,
  RouteInventoryMovementTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'employee_marilin_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
