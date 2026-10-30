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

  group('Database Schema Migration V12 -> V13', () {
    late AppDatabase db;

    test('re-running 12->13 on an upgraded db keeps the column and the data', () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      await fresh.customStatement(
        "INSERT INTO products (product_id, name, price, container_type_id) "
        "VALUES ('p-1', 'Agua 20L', 1500, 7)",
      );
      final before = await fresh.customSelect('SELECT * FROM products').get();

      await fresh.migration.onUpgrade(fresh.createMigrator(), 12, 13);

      final after = await fresh.customSelect('SELECT * FROM products').get();
      expect(after.map((r) => r.data).toList(), before.map((r) => r.data).toList());
      final column = (await fresh.customSelect('PRAGMA table_info(products)').get())
          .firstWhere((r) => r.read<String>('name') == 'container_type_id');
      expect(column.read<int>('notnull'), 0);
      await fresh.close();
    });

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v12 shape: products without their container type link.
      await db.customStatement('ALTER TABLE products DROP COLUMN container_type_id');
      await db.customStatement(
        "INSERT INTO products (product_id, name, price) VALUES ('p-1', 'Agua 20L', 1500)",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adds the container type link and keeps existing products without one', () async {
      await db.migration.onUpgrade(db.createMigrator(), 12, 13);

      final product = await db.select(db.productTable).getSingle();
      expect(product.name, 'Agua 20L');
      expect(product.containerTypeId, isNull);
    });

  });

  group('Database Schema Migration V13 -> V14', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v13 shape: no neighborhood catalog yet.
      await db.customStatement('DROP TABLE neighborhoods');
      await db.customStatement(
        "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Kiosco Norte')",
      );
      await db.customStatement(
        "INSERT INTO customer_addresses (address_id, customer_id, street, neighborhood, is_primary) "
        "VALUES ('a-1', 'c-1', 'Belgrano 340', 'Centro', 1)",
      );
      await db.customStatement(
        "INSERT INTO payment_methods (id, code, name) VALUES (5, 'CASH', 'Cash')",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('creates an empty neighborhood catalog and keeps existing data', () async {
      Future<List<Map<String, Object?>>> rows(String table) async =>
          (await db.customSelect('SELECT * FROM $table').get())
              .map((r) => r.data)
              .toList();
      final customers = await rows('customers');
      final addresses = await rows('customer_addresses');
      final methods = await rows('payment_methods');

      await db.migration.onUpgrade(db.createMigrator(), 13, 14);

      expect(await db.select(db.neighborhoodTable).get(), isEmpty);
      await db.into(db.neighborhoodTable).insert(
            NeighborhoodTableCompanion.insert(
              id: const drift.Value(1),
              name: 'Centro',
            ),
          );
      expect((await db.select(db.neighborhoodTable).getSingle()).enabled, isTrue);
      expect(await rows('customers'), customers);
      expect(await rows('customer_addresses'), addresses);
      expect(await rows('payment_methods'), methods);
    });

    test('re-running 13->14 keeps the stored catalog', () async {
      await db.migration.onUpgrade(db.createMigrator(), 13, 14);
      await db.customStatement(
        "INSERT INTO neighborhoods (id, name, enabled) VALUES (1, 'Centro', 1)",
      );

      await db.migration.onUpgrade(db.createMigrator(), 13, 14);

      expect((await db.select(db.neighborhoodTable).getSingle()).name, 'Centro');
    });

  });

  group('Database Schema Migration V14 -> V15', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v14 shape: sales without a status, no cancellation
      // fields on sales or payments.
      for (final statement in [
        'ALTER TABLE sales DROP COLUMN status',
        'ALTER TABLE sales DROP COLUMN cancelled_at',
        'ALTER TABLE sales DROP COLUMN cancellation_reason',
        'ALTER TABLE payments DROP COLUMN cancelled_at',
        'ALTER TABLE payments DROP COLUMN cancellation_reason',
      ]) {
        await db.customStatement(statement);
      }
      await db.customStatement(
        "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Kiosco Norte')",
      );
      await db.customStatement(
        'INSERT INTO sales (sale_id, customer_id, total_amount, payment_method, '
        "quantity, shipping_amount, visit_id) VALUES ('sale-1', 'c-1', 2400, "
        "'cash', 0, 0, 's-1')",
      );
      await db.customStatement(
        'INSERT INTO payments (payment_id, customer_id, amount, payment_method, '
        "sale_id) VALUES ('pay-1', 'c-1', 2400, 'EFECTIVO', 'sale-1')",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adds the cancellation fields and keeps existing sales and payments '
        'confirmed', () async {
      await db.migration.onUpgrade(db.createMigrator(), 14, 15);

      final sale = await db.select(db.saleTable).getSingle();
      expect(sale.saleId, 'sale-1');
      expect(sale.totalAmount, 2400);
      expect(sale.status, 'CONFIRMED');
      expect(sale.cancelledAt, isNull);
      expect(sale.cancellationReason, isNull);
      final payment = await db.select(db.paymentTable).getSingle();
      expect(payment.paymentId, 'pay-1');
      expect(payment.saleId, 'sale-1');
      expect(payment.status, 'CONFIRMED');
      expect(payment.cancelledAt, isNull);
      expect(payment.cancellationReason, isNull);
    });

    test('re-running 14->15 keeps the stored values', () async {
      await db.migration.onUpgrade(db.createMigrator(), 14, 15);
      await db.customStatement(
        "UPDATE sales SET status = 'CANCELLED', cancellation_reason = 'x'",
      );

      await db.migration.onUpgrade(db.createMigrator(), 14, 15);

      final sale = await db.select(db.saleTable).getSingle();
      expect(sale.status, 'CANCELLED');
      expect(sale.cancellationReason, 'x');
    });

  });

  group('Database Schema Migration V15 -> V16', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Rebuild the v15 shape: container movements without their sale or
      // reversed movement.
      await db.customStatement(
        'ALTER TABLE container_movements DROP COLUMN sale_id',
      );
      await db.customStatement(
        'ALTER TABLE container_movements DROP COLUMN reverses_movement_id',
      );
      await db.customStatement(
        "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Kiosco Norte')",
      );
      await db.customStatement(
        'INSERT INTO container_movements (container_movement_id, customer_id, '
        'container_type, delivered_quantity, returned_quantity, visit_id, '
        "server_id) VALUES ('mov-1', 'c-1', 'BIDON_20L', 2, 1, 's-1', 801)",
      );
      await db.customStatement(
        'INSERT INTO pending_changes (entity, entity_id, action) '
        "VALUES ('container_movement', 'mov-1', 'insert')",
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adds the sale and reversal links and keeps existing movements and '
        'their pending changes', () async {
      final pending = (await db.customSelect('SELECT * FROM pending_changes')
              .get())
          .map((r) => r.data)
          .toList();

      await db.migration.onUpgrade(db.createMigrator(), 15, 16);

      final movement = await db.select(db.containerMovementTable).getSingle();
      expect(movement.containerMovementId, 'mov-1');
      expect(movement.customerId, 'c-1');
      expect(movement.containerType, 'BIDON_20L');
      expect(movement.deliveredQuantity, 2);
      expect(movement.returnedQuantity, 1);
      expect(movement.visitId, 's-1');
      expect(movement.serverId, 801);
      expect(movement.saleId, isNull);
      expect(movement.reversesMovementId, isNull);
      expect(
        (await db.customSelect('SELECT * FROM pending_changes').get())
            .map((r) => r.data)
            .toList(),
        pending,
      );
    });

    test('re-running 15->16 keeps the stored links', () async {
      await db.migration.onUpgrade(db.createMigrator(), 15, 16);
      await db.customStatement(
        "UPDATE container_movements SET sale_id = 'sale-1', "
        "reverses_movement_id = 'mov-0'",
      );

      await db.migration.onUpgrade(db.createMigrator(), 15, 16);

      final movement = await db.select(db.containerMovementTable).getSingle();
      expect(movement.saleId, 'sale-1');
      expect(movement.reversesMovementId, 'mov-0');
    });

    test('the schema version is 16', () {
      expect(db.schemaVersion, 16);
    });
  });
}
