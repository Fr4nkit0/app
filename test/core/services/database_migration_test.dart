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

      // AuditLogTable
      await db
          .into(db.auditLogTable)
          .insert(
            AuditLogTableCompanion.insert(
              auditLogId: const drift.Value('log-1'),
              tableNameColumn: 'sales',
              recordId: 'sale-1',
              action: 'INSERT',
              payload: const drift.Value('{}'),
            ),
          );
      final logs = await db.select(db.auditLogTable).get();
      expect(logs.length, 1);

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
}
