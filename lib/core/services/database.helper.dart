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
import 'package:app/features/sync/data/database/pending_change.table.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(paymentTable);
        await m.createTable(customerAccountEntryTable);
        await m.createTable(customerBalanceTable);
        await m.createTable(containerMovementTable);
        await m.createTable(customerContainerBalanceTable);
        await m.createTable(routeInventoryLoadTable);
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
      if (from < 5) {
        final columns = await customSelect("PRAGMA table_info(customer_addresses)").get();
        final columnNames = columns.map((row) => row.read<String>('name')).toList();
        if (!columnNames.contains('neighborhood')) {
          await m.addColumn(customerAddressTable, customerAddressTable.neighborhood);
        }
      }
      if (from < 6) {
        final tables = <TableInfo<Table, dynamic>>[
          customerTable, customerAddressTable, customerPreferenceTable,
          routeTable, routeStopTable, routeInventoryTable, productTable,
          visitTable, saleTable, saleItemTable, paymentTable,
          customerAccountEntryTable, customerBalanceTable,
          containerMovementTable, customerContainerBalanceTable,
          routeInventoryLoadTable,
        ];
        for (final table in tables) {
          final columns = await customSelect("PRAGMA table_info(${table.actualTableName})").get();
          final columnNames = columns.map((row) => row.read<String>('name')).toList();
          if (!columnNames.contains('server_id')) {
            await m.addColumn(table, (table as dynamic).serverId);
          }
        }
      }
      if (from < 7) {
        await m.createTable(pendingChangeTable);
        await _replaceAuditLogsWithPendingChanges();
      }
    },
  );

  /// Moves unsynced audit rows into the pending queue and drops the old table.
  Future<void> _replaceAuditLogsWithPendingChanges() async {
    final legacy = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'audit_logs'",
    ).get();
    if (legacy.isEmpty) return;

    await customStatement('''
      INSERT INTO pending_changes
        (entity, entity_id, action, payload, status, created_at, last_modified_date)
      SELECT
        CASE table_name
          WHEN 'payments' THEN 'payment'
          ELSE 'container_movement'
        END,
        record_id, lower(action), payload, 'pending', created_at, last_modified_date
      FROM audit_logs
      WHERE enabled = 1 AND table_name IN ('payments', 'container_movements')
      ORDER BY created_at, rowid
    ''');
    await customStatement('DROP TABLE audit_logs');
  }

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
