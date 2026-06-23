import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/customers/data/database/customer.table.dart';
import '../../features/customers/data/database/customer.address.table.dart';
import '../../features/customers/data/database/customer.preference.table.dart';
import 'package:app/features/route/data/repositories/database/route.stop.table.dart';
import 'package:app/features/route/data/repositories/database/route.inventory.table.dart';
import 'package:app/features/route/data/repositories/database/route.table.dart';
import 'package:app/features/products/data/database/product.table.dart';
import 'package:app/features/visits/data/database/visit.table.dart';
import 'package:app/features/sales/data/database/sales.table.dart';
import 'package:app/features/sales/data/database/sale.item.dart';
import 'package:app/features/payments/data/database/payment.table.dart';
import 'package:app/features/inventory/data/database/container.table.dart';
import 'package:app/features/sync/data/database/audit_log.table.dart';

import 'database_mixins.dart';
import 'database_seed.dart';

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
    AuditLogTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDatabase(this);
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(paymentTable);
        await m.createTable(customerAccountEntryTable);
        await m.createTable(customerBalanceTable);
        await m.createTable(containerMovementTable);
        await m.createTable(customerContainerBalanceTable);
        await m.createTable(routeInventoryLoadTable);
        await m.createTable(auditLogTable);
      }
      if (from < 4) {
        final columns = await customSelect("PRAGMA table_info(customer_addresses)").get();
        final columnNames = columns.map((row) => row.read<String>('name')).toList();
        if (!columnNames.contains('latitude')) {
          await m.addColumn(customerAddressTable, customerAddressTable.latitude);
        }
        if (!columnNames.contains('longitude')) {
          await m.addColumn(customerAddressTable, customerAddressTable.longitude);
        }
      }
    },
    beforeOpen: (details) async {
      if (details.wasCreated) return;
      final existing = await (select(customerTable)..limit(1)).get();
      if (existing.isEmpty) {
        await seedDatabase(this);
      }
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
