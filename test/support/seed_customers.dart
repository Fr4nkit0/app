import 'package:app/core/services/database.helper.dart';
import 'package:drift/drift.dart';

/// Test fixture: four customers (mock-customer-1..4), each with a primary
/// address and a preference. Production never seeds data; tests opt in.
Future<void> seedTestCustomers(AppDatabase db) async {
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
  });
}
