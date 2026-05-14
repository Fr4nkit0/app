import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriftCustomerRepository implements CustomerRepository {
  final AppDatabase db;

  DriftCustomerRepository(this.db);

  @override
  Future<Resource<void>> saveCustomer(Customer customer) async {
    try {
      return await db.transaction(() async {
        await db
            .into(db.customerTable)
            .insertOnConflictUpdate(
              CustomerTableCompanion.insert(
                customerId: Value(customer.id),
                name: customer.name,
                phone: Value(customer.phone),
              ),
            );
        for (final address in customer.addresses) {
          await db
              .into(db.customerAddressTable)
              .insertOnConflictUpdate(
                CustomerAddressTableCompanion.insert(
                  addressId: Value(address.id),
                  customerId: Value(customer.id),
                  street: Value(address.street),
                  apartment: Value(address.apartment),
                  floor: Value(address.floor),
                  visualReference: Value(address.visualReference),
                  isPrimary: Value(address.isPrimary),
                ),
              );
        }
        for (final pref in customer.preferences) {
          await db
              .into(db.customerPreferenceTable)
              .insertOnConflictUpdate(
                CustomerPreferenceTableCompanion.insert(
                  customerPreferenceId: Value(pref.id),
                  customerId: Value(customer.id),
                  dayOfWeek: Value(pref.dayOfWeek),
                  timeWindowStart: pref.timeWindowStart,
                  timeWindowEnd: Value(pref.timeWindowEnd),
                ),
              );
        }
        return const Resource.success(null);
      });
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Stream<int> watchCustomerCount() {
    final countExpr = db.customerTable.customerId.count();
    return (db.selectOnly(db.customerTable)..addColumns([countExpr]))
        .map((row) => row.read(countExpr) ?? 0)
        .watchSingle();
  }

  @override
  Stream<List<Customer>> watchAllCustomers() {
    return db
        .select(db.customerTable)
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => Customer(
                  id: row.customerId,
                  name: row.name,
                  phone: row.phone,
                  addresses: const [],
                  preferences: const [],
                ),
              )
              .toList(),
        );
  }
}

final driftCustomerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftCustomerRepository(db);
});
