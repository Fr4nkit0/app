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
import 'package:app/features/payments/data/database/payment_method.table.dart';
import 'package:app/features/visits/data/database/visit_outcome.table.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// 17 is the development baseline: one schema, no upgrade history. Before
  /// the first production release this version must be frozen, and every
  /// later schema change must ship with its own upgrade step.
  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    // Any older development schema is rebuilt empty; unsent local data is
    // lost, the same as reinstalling the app.
    onUpgrade: (m, from, to) async {
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
