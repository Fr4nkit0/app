import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/customers/data/database/customer.table.dart';
import '../../features/customers/data/database/customer.address.table.dart';
import '../../features/customers/data/database/customer.preference.table.dart';
import '../../features/customers/data/database/neighborhood.table.dart';
import 'package:app/features/route/data/database/route.stop.table.dart';
import 'package:app/features/route/data/database/route.inventory.table.dart';
import 'package:app/features/route/data/database/route.table.dart';
import 'package:app/features/products/data/database/product.table.dart';
import 'package:app/features/visits/data/database/visit.table.dart';
import 'package:app/features/sales/data/database/sales.table.dart';
import 'package:app/features/sales/data/database/sale.item.dart';
import 'package:app/features/payments/data/database/payment.table.dart';
import 'package:app/features/inventory/data/database/container.table.dart';
import 'package:app/features/sync/data/database/pending_change.table.dart';
import 'package:app/features/sync/data/database/sync_state.table.dart';
import 'package:app/features/customers/data/database/customer.agreement.table.dart';
import 'package:app/features/inventory/data/database/container_type.table.dart';
import 'package:app/features/inventory/data/database/route_container_load.table.dart';
import 'package:app/features/payments/data/database/payment_method.table.dart';
import 'package:app/features/visits/data/database/visit_outcome.table.dart';
import 'package:app/features/balance_corrections/data/database/balance_correction.table.dart';

import 'database_mixins.dart';

part 'database.helper.g.dart';

@DriftDatabase(
  tables: [
    CustomerTable,
    CustomerAddressTable,
    CustomerPreferenceTable,
    RouteTable,
    RouteStopTable,
    RouteInventoryTable,
    ProductTable,
    VisitTable,
    SaleTable,
    SaleItemTable,
    PaymentTable,
    CustomerAccountEntryTable,
    CustomerBalanceTable,
    ContainerMovementTable,
    CustomerContainerBalanceTable,
    RouteInventoryLoadTable,
    PendingChangeTable,
    ContainerTypeTable,
    PaymentMethodTable,
    VisitOutcomeTable,
    CustomerAgreementTable,
    SyncStateTable,
    NeighborhoodTable,
    BalanceCorrectionTable,
    RouteContainerLoadTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// 18 is the development baseline. 19 adds `balance_corrections` with its
  /// own upgrade step, so devices on 18 keep their unsent changes; anything
  /// older is still rebuilt empty. 20 adds `route_stops.position`, 21 adds
  /// `route_container_loads`, 22 drops the unique rule on `customers.phone`.
  @override
  int get schemaVersion => 22;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    // Any older development schema is rebuilt empty; unsent local data is
    // lost, the same as reinstalling the app.
    onUpgrade: (m, from, to) async {
      if (from >= 18 && from <= 21) {
        if (from == 18) await m.createTable(balanceCorrectionTable);
        if (from <= 19) {
          await m.addColumn(routeStopTable, routeStopTable.position);
        }
        if (from <= 20) await m.createTable(routeContainerLoadTable);
        // Rebuilds the table without the unique phone rule, keeping its rows.
        // Foreign keys are never enforced, so dependents are left untouched.
        await m.alterTable(TableMigration(customerTable));
        return;
      }
      // Reverse declaration order drops dependents before what they reference.
      for (final entity in allSchemaEntities.toList().reversed) {
        await m.drop(entity);
      }
      await m.createAll();
    },
  );

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
