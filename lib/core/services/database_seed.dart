import 'dart:io';
import 'package:drift/drift.dart';
import 'database.helper.dart';

Future<void> seedDatabase(AppDatabase db) async {
  // Seed Customers
  final customers = [
    (
      id: 'mock-customer-1',
      name: 'José García',
      phone: '387-555-0101',
      addressId: 'mock-addr-1',
      street: 'Av. San Martín 1300',
      prefId: 'mock-pref-1',
      dayOfWeek: 1, // Lunes
      start: '08:00',
      end: '12:00',
    ),
    (
      id: 'mock-customer-2',
      name: 'Laura Gómez',
      phone: '387-555-0202',
      addressId: 'mock-addr-2',
      street: 'mza 517 C',
      prefId: 'mock-pref-2',
      dayOfWeek: 2, // Martes
      start: '14:00',
      end: '18:00',
    ),
    (
      id: 'mock-customer-3',
      name: "Despensa 'El Sol'",
      phone: '387-555-0303',
      addressId: 'mock-addr-3',
      street: 'mza 77 A',
      prefId: 'mock-pref-3',
      dayOfWeek: 3, // Miércoles
      start: '09:00',
      end: '13:00',
    ),
    (
      id: 'mock-customer-4',
      name: 'Kiosco Don Juan',
      phone: '387-555-0404',
      addressId: 'mock-addr-4',
      street: 'mza 912 D',
      prefId: 'mock-pref-4',
      dayOfWeek: 4, // Jueves
      start: '15:00',
      end: '19:00',
    ),
  ];

  await db.transaction(() async {
    for (final c in customers) {
      // 1. Insert Customer
      await db
          .into(db.customerTable)
          .insertOnConflictUpdate(
            CustomerTableCompanion.insert(
              customerId: Value(c.id),
              name: c.name,
              phone: Value(c.phone),
            ),
          );

      // 2. Insert Customer Address
      await db
          .into(db.customerAddressTable)
          .insertOnConflictUpdate(
            CustomerAddressTableCompanion.insert(
              addressId: Value(c.addressId),
              customerId: Value(c.id),
              street: Value(c.street),
              isPrimary: const Value(true),
            ),
          );

      // 3. Insert Customer Preference
      await db
          .into(db.customerPreferenceTable)
          .insertOnConflictUpdate(
            CustomerPreferenceTableCompanion.insert(
              customerPreferenceId: Value(c.prefId),
              customerId: Value(c.id),
              dayOfWeek: Value(c.dayOfWeek),
              timeWindowStart: c.start,
              timeWindowEnd: Value(c.end),
            ),
          );
    }

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayDate = DateTime.now();

      // 1. products
      await db
          .into(db.productTable)
          .insertOnConflictUpdate(
            ProductTableCompanion.insert(
              productId: const Value('mock-prod-1'),
              name: 'Bidón 20L',
              price: 6500.0,
            ),
          );
      await db
          .into(db.productTable)
          .insertOnConflictUpdate(
            ProductTableCompanion.insert(
              productId: const Value('mock-prod-2'),
              name: 'Sifón 1.5L',
              price: 1500.0,
            ),
          );

      // 2. routes
      await db
          .into(db.routeTable)
          .insertOnConflictUpdate(
            RouteTableCompanion.insert(
              routeId: const Value('mock-route-1'),
              route_date: todayStr,
            ),
          );

      // 3. route_stops
      for (var i = 1; i <= 4; i++) {
        await db
            .into(db.routeStopTable)
            .insertOnConflictUpdate(
              RouteStopTableCompanion.insert(
                routeStopId: Value('mock-stop-$i'),
                routeId: 'mock-route-1',
                customerId: 'mock-customer-$i',
                customerAddressId: Value('mock-addr-$i'),
                sequence: i,
                status: const Value('pending'),
                scheduledAt: todayDate,
              ),
            );
      }

      // 4. visits
      for (var i = 1; i <= 4; i++) {
        await db
            .into(db.visitTable)
            .insertOnConflictUpdate(
              VisitTableCompanion.insert(
                visitId: Value('mock-visit-$i'),
                routeStopId: 'mock-stop-$i',
                customerId: 'mock-customer-$i',
                visitType: 'sale',
                outcome: const Value('successful'),
                arrived_at: todayDate,
              ),
            );
      }

      // 5. sales
      await db
          .into(db.saleTable)
          .insertOnConflictUpdate(
            SaleTableCompanion.insert(
              saleId: const Value('mock-sale-1'),
              customerId: 'mock-customer-1',
              totalAmount: 19500.0,
              paymentMethod: 'cash',
              quantity: 3,
              shipping_amount: 0.0,
              visitId: const Value('mock-visit-1'),
              saleDate: Value(todayDate),
            ),
          );

      // 6. sale_items
      await db
          .into(db.saleItemTable)
          .insertOnConflictUpdate(
            SaleItemTableCompanion.insert(
              saleItemId: const Value('mock-sale-item-1'),
              saleId: 'mock-sale-1',
              productId: 'mock-prod-1',
              quantity: 3,
              unitPrice: 6500.0,
              subtotal: 19500.0,
            ),
          );

      // 7. payments
      await db
          .into(db.paymentTable)
          .insertOnConflictUpdate(
            PaymentTableCompanion.insert(
              paymentId: const Value('mock-pay-1'),
              customerId: 'mock-customer-3',
              amount: 1000.0,
              paymentMethod: 'cash',
              status: const Value('CONFIRMED'),
              visitId: const Value('mock-visit-3'),
            ),
          );

      // 8. customer_account_entries
      await db
          .into(db.customerAccountEntryTable)
          .insertOnConflictUpdate(
            CustomerAccountEntryTableCompanion.insert(
              customerAccountEntryId: const Value('mock-cae-1'),
              customerId: 'mock-customer-1',
              entryType: 'SALE',
              amount: 19500.0,
              direction: 1,
              saleId: const Value('mock-sale-1'),
            ),
          );

      // 9. customer_balances
      for (var i = 1; i <= 4; i++) {
        await db
            .into(db.customerBalanceTable)
            .insertOnConflictUpdate(
              CustomerBalanceTableCompanion.insert(
                customerId: 'mock-customer-$i',
                currentBalance: const Value(0.0),
              ),
            );
      }

      // 10. container_movements
      await db
          .into(db.containerMovementTable)
          .insertOnConflictUpdate(
            ContainerMovementTableCompanion.insert(
              containerMovementId: const Value('mock-cm-1'),
              customerId: 'mock-customer-1',
              containerType: 'BIDON_20L',
              deliveredQuantity: 3,
              returnedQuantity: 0,
              visitId: const Value('mock-visit-1'),
              routeId: const Value('mock-route-1'),
            ),
          );

      // 11. customer_container_balances
      await db
          .into(db.customerContainerBalanceTable)
          .insertOnConflictUpdate(
            CustomerContainerBalanceTableCompanion.insert(
              customerId: 'mock-customer-1',
              containerType: 'BIDON_20L',
              quantity: const Value(3),
            ),
          );

      // 12. inventory_movements
      await db
          .into(db.routeInventoryTable)
          .insertOnConflictUpdate(
            RouteInventoryTableCompanion.insert(
              inventoryMovementId: const Value('mock-im-1'),
              productId: 'mock-prod-1',
              movementType: 'in',
              quantity: 100,
              reason: 'restock',
            ),
          );
      await db
          .into(db.routeInventoryTable)
          .insertOnConflictUpdate(
            RouteInventoryTableCompanion.insert(
              inventoryMovementId: const Value('mock-im-2'),
              productId: 'mock-prod-2',
              movementType: 'in',
              quantity: 150,
              reason: 'restock',
            ),
          );

      // 13. route_inventory_loads
      await db
          .into(db.routeInventoryLoadTable)
          .insertOnConflictUpdate(
            RouteInventoryLoadTableCompanion.insert(
              routeInventoryLoadId: const Value('mock-ril-1'),
              routeId: 'mock-route-1',
              productId: 'mock-prod-1',
              quantity: 100,
            ),
          );
      await db
          .into(db.routeInventoryLoadTable)
          .insertOnConflictUpdate(
            RouteInventoryLoadTableCompanion.insert(
              routeInventoryLoadId: const Value('mock-ril-2'),
              routeId: 'mock-route-1',
              productId: 'mock-prod-2',
              quantity: 150,
            ),
          );

      // 14. audit_logs
      await db
          .into(db.auditLogTable)
          .insertOnConflictUpdate(
            AuditLogTableCompanion.insert(
              auditLogId: const Value('mock-audit-1'),
              tableNameColumn: 'sales',
              recordId: 'mock-sale-1',
              action: 'insert',
            ),
          );
    }
  });
}
