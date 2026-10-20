import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:app/core/services/database.helper.dart';

void main() {
  group('Database Schema Migration V2 -> V3', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Migration creates new tables and preserves customer data', () async {
      // 1. Insert data under version 2 schema
      final customerCompanion = CustomerTableCompanion.insert(
        customerId: const drift.Value('cust-123'),
        name: 'John Doe',
        phone: const drift.Value('12345678'),
      );
      await db.into(db.customerTable).insert(customerCompanion);

      final customersBefore = await db.select(db.customerTable).get();
      expect(customersBefore.length, 1);
      expect(customersBefore.any((c) => c.name == 'John Doe'), isTrue);

      // 2. Perform migration
      final migrator = db.migration;
      final m = db.createMigrator();
      await migrator.onUpgrade(m, 2, 3);

      // 3. Verify that the 7 new tables can be written to/read from

      // PaymentTable
      await db
          .into(db.paymentTable)
          .insert(
            PaymentTableCompanion.insert(
              paymentId: const drift.Value('pay-1'),
              customerId: 'cust-123',
              amount: 1500.0,
              paymentMethod: 'cash',
            ),
          );
      final payments = await db.select(db.paymentTable).get();
      expect(payments.length, 1);
      expect(payments.first.amount, 1500.0);

      // CustomerAccountEntryTable
      await db
          .into(db.customerAccountEntryTable)
          .insert(
            CustomerAccountEntryTableCompanion.insert(
              customerAccountEntryId: const drift.Value('entry-1'),
              customerId: 'cust-123',
              entryType: 'payment',
              amount: 1500.0,
              direction: 1,
            ),
          );
      final entries = await db.select(db.customerAccountEntryTable).get();
      expect(entries.length, 1);

      // CustomerBalanceTable
      await db
          .into(db.customerBalanceTable)
          .insert(
            CustomerBalanceTableCompanion.insert(
              customerId: 'cust-123',
              currentBalance: const drift.Value(1500.0),
            ),
          );
      final balances = await db.select(db.customerBalanceTable).get();
      expect(balances.length, 1);

      // ContainerMovementTable
      await db
          .into(db.containerMovementTable)
          .insert(
            ContainerMovementTableCompanion.insert(
              containerMovementId: const drift.Value('mov-1'),
              customerId: 'cust-123',
              containerType: 'BIDON_20L',
              deliveredQuantity: 2,
              returnedQuantity: 3,
            ),
          );
      final movements = await db.select(db.containerMovementTable).get();
      expect(movements.length, 1);

      // CustomerContainerBalanceTable
      await db
          .into(db.customerContainerBalanceTable)
          .insert(
            CustomerContainerBalanceTableCompanion.insert(
              customerId: 'cust-123',
              containerType: 'BIDON_20L',
              quantity: const drift.Value(4),
            ),
          );
      final containerBalances = await db
          .select(db.customerContainerBalanceTable)
          .get();
      expect(containerBalances.length, 1);

      // RouteInventoryLoadTable
      await db
          .into(db.routeInventoryLoadTable)
          .insert(
            RouteInventoryLoadTableCompanion.insert(
              routeInventoryLoadId: const drift.Value('load-1'),
              routeId: 'route-1',
              productId: 'prod-1',
              quantity: 10,
            ),
          );
      final loads = await db.select(db.routeInventoryLoadTable).get();
      expect(loads.length, 1);

      // PendingChangeTable
      await db
          .into(db.pendingChangeTable)
          .insert(
            PendingChangeTableCompanion.insert(
              entity: 'sale',
              entityId: 'sale-1',
              action: 'insert',
              payload: const drift.Value('{}'),
            ),
          );
      final pending = await db.select(db.pendingChangeTable).get();
      expect(pending.length, 1);

      // 4. Verify existing customer data is preserved after migration
      final customersAfter = await db.select(db.customerTable).get();
      expect(customersAfter.length, 1);
      expect(customersAfter.any((c) => c.name == 'John Doe'), isTrue);
    });
  });

  group('Database Schema Migration V4 -> V5', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Migration adds neighborhood column to customer_addresses and preserves data',
      () async {
        final customerCompanion = CustomerTableCompanion.insert(
          customerId: const drift.Value('cust-456'),
          name: 'Jane Smith',
          phone: const drift.Value('87654321'),
        );
        await db.into(db.customerTable).insert(customerCompanion);

        await db.customStatement(
          "INSERT INTO customer_addresses (address_id, customer_id, street, is_primary) "
          "VALUES ('addr-456', 'cust-456', 'Calle Falsa 123', 1)",
        );

        final migrator = db.migration;
        final m = db.createMigrator();
        await migrator.onUpgrade(m, 4, 5);

        final results = await db
            .customSelect(
              "SELECT * FROM customer_addresses WHERE address_id = 'addr-456'",
            )
            .get();
        expect(results.length, 1);
        final row = results.first;
        expect(row.read<String?>('street'), 'Calle Falsa 123');
        expect(row.data.containsKey('neighborhood'), isTrue);
        expect(row.read<String?>('neighborhood'), isNull);
      },
    );
  });

  group('Database Schema Migration V6 -> V7', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v6 shape: audit_logs instead of pending_changes.
      await db.customStatement('DROP TABLE pending_changes');
      await db.customStatement('''
        CREATE TABLE audit_logs (
          audit_log_id TEXT NOT NULL PRIMARY KEY,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          action TEXT NOT NULL,
          payload TEXT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          last_modified_date INTEGER NOT NULL DEFAULT (strftime('%s','now')),
          enabled INTEGER NOT NULL DEFAULT 1,
          server_id INTEGER NULL
        )
      ''');
    });

    tearDown(() async {
      await db.close();
    });

    test('moves unsynced audit rows into the queue and drops audit_logs', () async {
      await db.customStatement(
        "INSERT INTO audit_logs (audit_log_id, table_name, record_id, action, payload, created_at, enabled) VALUES "
        "('l1', 'payments', 'pay-1', 'INSERT', '{\"amount\":5}', 100, 1), "
        "('l2', 'container_movements', 'mov-1', 'INSERT', '{}', 200, 1), "
        "('l3', 'payments', 'pay-old', 'INSERT', '{}', 50, 0)",
      );

      await db.migration.onUpgrade(db.createMigrator(), 6, 7);

      final queue = await db.select(db.pendingChangeTable).get();
      expect(queue.map((r) => (r.entity, r.entityId, r.action, r.status)), [
        ('payment', 'pay-1', 'insert', 'pending'),
        ('container_movement', 'mov-1', 'insert', 'pending'),
      ]);
      expect(queue.first.payload, '{"amount":5}');

      final legacy = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name = 'audit_logs'",
          )
          .get();
      expect(legacy, isEmpty);
    });

    test('upgrading a database without audit_logs just creates the queue', () async {
      await db.customStatement('DROP TABLE audit_logs');

      await db.migration.onUpgrade(db.createMigrator(), 6, 7);

      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });
  });

  group('Database Schema Migration V8 -> V9', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v8 shape: catalogs without the enabled flag.
      for (final table in ['container_types', 'payment_methods', 'visit_outcomes']) {
        await db.customStatement('ALTER TABLE $table DROP COLUMN enabled');
      }
      await db.customStatement(
        "INSERT INTO visit_outcomes (id, name, triggers_reschedule) VALUES (3, 'Absent', 1)",
      );
      await db.customStatement(
        "INSERT INTO payment_methods (id, code, name) VALUES (5, 'CASH', 'Cash')",
      );
      await db.customStatement(
        "INSERT INTO container_types (id, code) VALUES (1, 'BIDON_20L')",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adds the enabled flag to catalogs and keeps existing rows enabled', () async {
      await db.migration.onUpgrade(db.createMigrator(), 8, 9);

      expect((await db.select(db.visitOutcomeTable).getSingle()).enabled, isTrue);
      expect((await db.select(db.paymentMethodTable).getSingle()).enabled, isTrue);
      expect((await db.select(db.containerTypeTable).getSingle()).enabled, isTrue);
    });
  });

  group('Database Schema Migration V9 -> V10', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v9 shape: sale lines without the agreement link.
      await db.customStatement('ALTER TABLE sale_items DROP COLUMN agreement_server_id');
      await db.customStatement(
        "INSERT INTO sale_items (sale_item_id, sale_id, product_id, quantity, unit_price, subtotal) "
        "VALUES ('si-1', 's-1', 'p-1', 2, 1500, 3000)",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adds the agreement link to sale lines and keeps existing lines at list price', () async {
      await db.migration.onUpgrade(db.createMigrator(), 9, 10);

      final line = await db.select(db.saleItemTable).getSingle();
      expect(line.unitPrice, 1500);
      expect(line.agreementServerId, isNull);
    });
  });

  group('Database Schema Migration V10 -> V11', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v10 shape: outcomes without their stable code.
      await db.customStatement('ALTER TABLE visit_outcomes DROP COLUMN code');
      await db.customStatement(
        "INSERT INTO visit_outcomes (id, name, triggers_reschedule) VALUES (3, 'Ausente', 0)",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adds the outcome code and keeps existing outcomes without one', () async {
      await db.migration.onUpgrade(db.createMigrator(), 10, 11);

      final outcome = await db.select(db.visitOutcomeTable).getSingle();
      expect(outcome.name, 'Ausente');
      expect(outcome.code, isNull);
    });
  });
}
